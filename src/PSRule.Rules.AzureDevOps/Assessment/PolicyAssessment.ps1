function Get-AzDevOpsAssessmentField {
    param([object]$TargetObject, [string]$Field)
    $names = if ($TargetObject -is [System.Collections.IDictionary]) { @($TargetObject.Keys) } else { @($TargetObject.psobject.Properties.Name) }
    if ($Field -in $names) { return $TargetObject.$Field }
    $value = $TargetObject
    foreach ($part in $Field.Split('.')) {
        if ($null -eq $value) { return $null }
        $value = $value.$part
    }
    return $value
}

function Get-AzDevOpsAssessmentAgentImages {
    param([object]$TargetObject)
    if ($TargetObject.pool.vmImage) { [string]$TargetObject.pool.vmImage }
    foreach ($child in @($TargetObject.stages) + @($TargetObject.jobs)) {
        if ($null -ne $child) { Get-AzDevOpsAssessmentAgentImages -TargetObject $child }
    }
}

function Get-AzDevOpsPolicyAssessment {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$TargetObject, [Parameter(Mandatory)][string]$RuleId, [object]$Policy)

    $notApplicable = [pscustomobject]@{ Outcome = 'NotApplicable'; ReasonCode = 'PolicyNotRequired' }
    $unknown = [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'PolicyEvidenceUnavailable' }
    $pass = [pscustomobject]@{ Outcome = 'Pass'; ReasonCode = 'PolicySatisfied' }
    $fail = [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'PolicyNotSatisfied' }
    # Public exposure remains restricted unless a referenced policy or public baseline approves it.
    if ($null -eq $Policy -and $RuleId -eq 'Azure.DevOps.Project.Visibility') {
        $Policy = @{ Reference = 'default-private-project'; Expected = 'private' }
    }
    if ($null -eq $Policy -and $RuleId -eq 'Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess') {
        $Policy = @{ Reference = 'default-no-anonymous-access'; Expected = $false }
    }
    if ($null -eq $Policy) { return $notApplicable }
    if (-not $Policy.Reference) { return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'PolicyReferenceMissing' } }
    if ($null -ne $Policy.Targets -and $TargetObject.ObjectName -notin @($Policy.Targets)) {
        if ($RuleId -eq 'Azure.DevOps.Project.Visibility') { $Policy = @{ Reference = 'default-private-project'; Expected = 'private' } }
        elseif ($RuleId -eq 'Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess') { $Policy = @{ Reference = 'default-no-anonymous-access'; Expected = $false } }
        else { return $notApplicable }
    }
    if ($Policy.Required -eq $false) { return $notApplicable }

    # Compensation is accepted only for the explicitly named control and reviewed evidence reference.
    if ($RuleId -match '(GitHubAdvancedSecurityEnabled|GitHubAdvancedSecurityBlockPushes|ProductionHumanApproval)$') {
        foreach ($control in $TargetObject.EquivalentControls) {
            if ($control.RuleId -eq $RuleId -and $control.Effective -eq $true -and
                $control.Reference -and $control.Reference -in @($Policy.ApprovedEquivalentControls)) {
                return [pscustomobject]@{ Outcome = 'Pass'; ReasonCode = 'ApprovedEquivalentControl' }
            }
        }
        if ($RuleId -match 'GitHubAdvancedSecurity' -and $Policy.Licensed -eq $false) { return $notApplicable }
    }

    if ($RuleId -like '*.ProductionHumanApproval') {
        if ($null -eq $TargetObject.Checks) { return $unknown }
        $approvals = @($TargetObject.Checks | Where-Object { $_.type.name -eq 'Approval' -and $_.isDisabled -ne $true })
        if ($approvals.Count -eq 0) { return $fail }
        $incomplete = $false
        foreach ($approval in $approvals) {
            if ($null -eq $approval.settings.approvers) { $incomplete = $true; continue }
            if (@($approval.settings.approvers).Count -gt 0) { return $pass }
        }
        if ($incomplete) { return $unknown }
        return $fail
    }
    if ($RuleId -eq 'Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest') {
        if ($null -eq $Policy.AllowedImages -or @($Policy.AllowedImages).Count -eq 0) { return $unknown }
        $images = @(Get-AzDevOpsAssessmentAgentImages -TargetObject $TargetObject)
        if ($images.Count -eq 0) { return $unknown }
        $incomplete = $false
        foreach ($image in $images) {
            if ($image -match '\$\(|\$\{\{') { $incomplete = $true; continue }
            if ($image -notin @($Policy.AllowedImages) -or $image -in @($Policy.RetiredImages)) { return $fail }
        }
        if ($incomplete) { return $unknown }
        return $pass
    }

    $fields = @{
        'Azure.DevOps.Organization.GeneralOverview.TimeZoneSet' = 'timeZone'
        'Azure.DevOps.Organization.GeneralOverview.GeographySet' = 'geography'
        'Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled' = 'isAssignmentBillingEnabled'
        'Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured' = 'isEnterpriseBillingEnabled'
        'Azure.DevOps.Repos.License' = 'LicenseExists'
        'Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled' = 'Ghas.advSecEnabled'
        'Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes' = 'Ghas.blockPushes'
        'Azure.DevOps.Organization.Security.Policies.DisallowSecureShell' = 'policy.disallowSecureShell'
        'Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess' = 'policy.disallowAadGuestUserAccess'
        'Azure.DevOps.Organization.Security.Policies.DisallowOAuthAuthentication' = 'policy.disallowOAuthAuthentication'
        'Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess' = 'policy.allowAnonymousAccess'
        'Azure.DevOps.Project.Visibility' = 'visibility'
        'Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays' = 'RetentionSettings.purgeArtifacts.value'
        'Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays' = 'RetentionSettings.purgePullRequestRuns.value'
    }
    if (-not $fields.ContainsKey($RuleId)) { return $unknown }
    $value = Get-AzDevOpsAssessmentField -TargetObject $TargetObject -Field $fields[$RuleId]
    if ($null -eq $value) { return $unknown }
    if ($RuleId -like 'Azure.DevOps.RetentionSettings.*') {
        [double]$minimum = 0; [double]$actual = 0
        if ($null -eq $Policy.Minimum -or -not [double]::TryParse([string]$Policy.Minimum, [ref]$minimum) -or
            -not [double]::TryParse([string]$value, [ref]$actual) -or $minimum -lt 0 -or $actual -lt 0) { return $unknown }
        if ($actual -ge $minimum) { return $pass }
        return $fail
    }
    $expected = $Policy.Expected
    if ($null -eq $expected -and $RuleId -match '^Azure.DevOps.Repos.(License|GitHubAdvancedSecurityEnabled|GitHubAdvancedSecurityBlockPushes)$') { $expected = $true }
    if ($null -eq $expected) { return $unknown }
    if ($value -in @($expected)) {
        if ($RuleId -eq 'Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess' -and $value -eq $false) {
            $evidence = $TargetObject.GuestAccessEvidence
            if ($null -eq $evidence -or $evidence.Status -ne 'Complete' -or -not $evidence.Reference -or
                $evidence.Reference -notin @($Policy.ApprovedGuestReviews) -or $null -eq $evidence.Guests -or $null -eq $Policy.ApprovedGuests) {
                return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'GuestGovernanceEvidenceUnavailable' }
            }
            foreach ($guest in $evidence.Guests) {
                if (-not $guest.Descriptor) { return $unknown }
                if ($guest.Descriptor -notin @($Policy.ApprovedGuests)) {
                    return [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'UnapprovedGuestAccess' }
                }
            }
        }
        return $pass
    }
    return $fail
}
