function Get-AzDevOpsAssessmentCatalog {
    [CmdletBinding()]
    param()
    Get-Content "$PSScriptRoot/../Assessment/catalog.json" -Raw | ConvertFrom-Json
}

function Get-AzDevOpsAssessmentHash {
    param([string]$Value)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { [BitConverter]::ToString($algorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes($Value))).Replace('-', '').ToLowerInvariant() }
    finally { $algorithm.Dispose() }
}

function ConvertTo-AzDevOpsAssessment {
    <#
    .SYNOPSIS
    Project detailed PSRule results into versioned assessment findings and correlated risk objectives.
    .DESCRIPTION
    Pass results obtained with -Outcome All and their original exported targets. Raw results
    remain unchanged. ScopeId must identify the organization/project represented by this run.
    Unknown evidence and unclassified severity prevent a complete security score.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Result,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TargetObject,
        [Parameter(Mandatory)][string]$ScopeId,
        [string]$Baseline = 'Baseline.Default',
        [System.Collections.IDictionary]$Configuration = @{}
    )
    $catalog = Get-AzDevOpsAssessmentCatalog
    $rules = @{}
    foreach ($rule in $catalog.Rules) { $rules[$rule.RuleId] = $rule }
    $unmapped = @($Result | Where-Object { -not $rules.ContainsKey($_.RuleName) -and $_.RuleName -notin @($catalog.SupplementalRules.RuleId) }).Count
    $targets = @{}
    foreach ($target in $TargetObject) {
        $key = "$($target.ObjectType)/$($target.ObjectName)"
        if ($targets.ContainsKey($key)) { throw "Duplicate target identity in assessment scope: $key" }
        $targets[$key] = $target
    }
    $findings = @()
    foreach ($raw in $Result) {
        $rule = $rules[$raw.RuleName]
        # Debug and supplemental runtime diagnostics are preserved by the caller's raw results.
        if ($null -eq $rule -or $raw.TargetType -ne $rule.TargetType) { continue }
        $target = $targets[$raw.TargetName]
        $outcome = [string]$raw.Outcome
        $reason = [string]$raw.OutcomeReason
        if ($reason -in @('Inconclusive', 'Error') -or $outcome -notin @('Pass', 'Fail', 'None')) {
            $outcome = 'Unknown'
        } elseif ($outcome -eq 'None') {
            if ($null -eq $target) {
                $outcome = 'Unknown'; $reason = 'OriginalTargetUnavailable'
            } elseif ($rule.Applicability -in @('Policy', 'DefaultPolicy')) {
                $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $target -RuleId $rule.RuleId -Policy $Configuration.assessmentPolicies.($rule.RuleId)
                $outcome = $assessment.Outcome; $reason = $assessment.ReasonCode
            } elseif ($rule.RuleId -like '*.InheritedPermissions') {
                $assessment = Get-AzDevOpsEffectivePermissionAssessment -Evidence $target.PermissionEvidence -Policy $Configuration.effectivePermissionPolicies.($rule.TargetType)
                $outcome = $assessment.Outcome; $reason = $assessment.ReasonCode
            } elseif ($rule.RuleId -like '*.ProductionCheckProtection') {
                $assessment = Get-AzDevOpsProductionGateAssessment -TargetObject $target
                $outcome = $assessment.Outcome; $reason = $assessment.ReasonCode
            } elseif ($rule.RiskGroup -eq 'VariableGroup.SecretExposure') {
                $assessment = Get-AzDevOpsVariableGroupSecretAssessment -TargetObject $target
                $outcome = $assessment.Outcome; $reason = $assessment.ReasonCode
            } else { $outcome = 'NotApplicable' }
            # A skipped diagnostic cannot become a proven pass/fail solely through projection.
            if ($outcome -in @('Pass', 'Fail')) { $outcome = 'Unknown'; $reason = 'RawDiagnosticNotEvaluated' }
        }
        $riskGroup = $rule.RiskGroup
        if ($rule.Correlation -eq 'MissingProductionGateOnly' -and $null -ne $target -and
            $outcome -eq 'Fail' -and (Get-AzDevOpsProductionGateAssessment -TargetObject $target).ReasonCode -in @('MissingProductionGate', 'DisabledProductionGate', 'InvalidProductionGate')) {
            $riskGroup = if ($rule.RuleId -like '*Environments*') { 'Environment.ProductionProtection' } else { 'ServiceConnection.ProductionProtection' }
        }
        $objectiveId = [ordered]@{ ScopeId = $ScopeId; TargetName = $raw.TargetName; RiskGroup = $riskGroup } | ConvertTo-Json -Compress
        $findings += [pscustomobject][ordered]@{
            RuleId = $rule.RuleId; TargetName = $raw.TargetName; TargetType = $raw.TargetType
            Outcome = $outcome; ReasonCode = $reason; RawOutcome = [string]$raw.Outcome
            RawOutcomeReason = [string]$raw.OutcomeReason; RawReasons = @($raw.Reason)
            Domain = $rule.Domain; AssessmentSeverity = $rule.AssessmentSeverity
            PSRuleLevel = $rule.PSRuleLevel; RiskGroup = $riskGroup; ObjectiveId = $objectiveId
            DeprecatedAlias = $rule.DeprecatedAlias
        }
    }
    $objectives = @()
    foreach ($group in $findings | Group-Object ObjectiveId) {
        $members = @($group.Group)
        $applicable = @($members | Where-Object Outcome -NE 'NotApplicable')
        $state = if ($members.Outcome -contains 'Fail') { 'Fail' } elseif ($members.Outcome -contains 'Unknown') { 'Unknown' } elseif ($members.Outcome -contains 'Pass') { 'Pass' } else { 'NotApplicable' }
        $severity = $null; $weight = $null
        if ($applicable.Count -gt 0 -and @($applicable | Where-Object { -not $_.AssessmentSeverity }).Count -eq 0) {
            foreach ($member in $applicable) {
                $candidate = $catalog.RiskWeights.($member.AssessmentSeverity)
                if ($null -eq $weight -or $candidate -gt $weight) { $weight = $candidate; $severity = $member.AssessmentSeverity }
            }
        }
        $objectives += [pscustomobject]@{
            ObjectiveId = $group.Name; TargetName = $members[0].TargetName; RiskGroup = $members[0].RiskGroup
            Domain = $members[0].Domain; Outcome = $state; AssessmentSeverity = $severity; Weight = $weight
            DiagnosticRuleIds = @($members.RuleId | Sort-Object -Unique)
        }
    }
    $security = @($objectives | Where-Object { $_.Domain -eq 'Security' -and $_.Outcome -ne 'NotApplicable' })
    $unknown = @($security | Where-Object Outcome -EQ 'Unknown').Count
    $unclassified = @($security | Where-Object { $null -eq $_.Weight }).Count
    [double]$totalWeight = ($security | Measure-Object Weight -Sum).Sum
    [double]$failedWeight = ($security | Where-Object Outcome -EQ 'Fail' | Measure-Object Weight -Sum).Sum
    $score = if ($unknown -eq 0 -and $unclassified -eq 0 -and $unmapped -eq 0 -and $totalWeight -gt 0) { [Math]::Round(100 * (1 - $failedWeight / $totalWeight), 2) } else { $null }
    $configurationHash = Get-AzDevOpsAssessmentHash ($Configuration | ConvertTo-Json -Depth 50 -Compress)
    $coverageHash = Get-AzDevOpsAssessmentHash (@($security.ObjectiveId | Sort-Object) | ConvertTo-Json -Compress)
    $comparisonKey = Get-AzDevOpsAssessmentHash (@($ScopeId, $Baseline, $catalog.RuleSetVersion, $catalog.SeverityPolicyVersion, $configurationHash, $coverageHash) | ConvertTo-Json -Compress)
    [pscustomobject][ordered]@{
        SchemaVersion = 1; RuleSetVersion = $catalog.RuleSetVersion; SeverityPolicyVersion = $catalog.SeverityPolicyVersion
        ScopeId = $ScopeId; Baseline = $Baseline; ConfigurationHash = $configurationHash; CoverageHash = $coverageHash; ComparisonKey = $comparisonKey
        Findings = $findings; RiskObjectives = $objectives
        Summary = [pscustomobject]@{
            DiagnosticCount = $findings.Count; UnmappedDiagnosticCount = $unmapped; RiskObjectiveCount = $objectives.Count
            UnknownSecurityObjectives = $unknown; UnclassifiedSecurityObjectives = $unclassified
            NotApplicableObjectives = @($objectives | Where-Object Outcome -EQ 'NotApplicable').Count
            KnownFailedSecurityWeight = $failedWeight; SecurityScore = $score
        }
    }
}

function Compare-AzDevOpsAssessment {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Previous, [Parameter(Mandatory)][object]$Current)
    $comparable = $Previous.ComparisonKey -and $Previous.ComparisonKey -eq $Current.ComparisonKey
    $delta = $null
    if ($comparable -and $null -ne $Previous.Summary.SecurityScore -and $null -ne $Current.Summary.SecurityScore) {
        $delta = $Current.Summary.SecurityScore - $Previous.Summary.SecurityScore
    }
    [pscustomobject]@{
        Comparable = [bool]$comparable
        ReasonCode = if ($comparable) { 'SameAssessmentPolicy' } else { 'AssessmentPolicyOrScopeChanged' }
        SecurityScoreDelta = $delta
        PreviousRuleSetVersion = $Previous.RuleSetVersion; CurrentRuleSetVersion = $Current.RuleSetVersion
        PreviousSeverityPolicyVersion = $Previous.SeverityPolicyVersion; CurrentSeverityPolicyVersion = $Current.SeverityPolicyVersion
    }
}
Export-ModuleMember -Function Get-AzDevOpsAssessmentCatalog, ConvertTo-AzDevOpsAssessment, Compare-AzDevOpsAssessment
