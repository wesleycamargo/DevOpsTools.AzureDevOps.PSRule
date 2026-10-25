BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}
Describe 'Referenced organizational policies' -Tag 'Unit' {
    It 'does not enforce an unspecified <Name> policy' -ForEach @(
        @{ Name = 'time zone'; Rule = 'Azure.DevOps.Organization.GeneralOverview.TimeZoneSet' }
        @{ Name = 'region'; Rule = 'Azure.DevOps.Organization.GeneralOverview.GeographySet' }
        @{ Name = 'SSH'; Rule = 'Azure.DevOps.Organization.Security.Policies.DisallowSecureShell' }
        @{ Name = 'retention'; Rule = 'Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays' }
        @{ Name = 'license'; Rule = 'Azure.DevOps.Repos.License' }
        @{ Name = 'human approval'; Rule = 'Azure.DevOps.ServiceConnections.ProductionHumanApproval' }
    ) {
        (Get-AzDevOpsPolicyAssessment -TargetObject @{} -RuleId $Rule).Outcome | Should -Be 'NotApplicable'
    }
    It 'evaluates allowed regions and treats unavailable evidence separately' {
        $rule = 'Azure.DevOps.Organization.GeneralOverview.GeographySet'
        $policy = @{ Reference = 'residency-policy-v1'; Expected = @('United States', 'Europe') }
        (Get-AzDevOpsPolicyAssessment @{ geography = 'United States' } $rule $policy).Outcome | Should -Be 'Pass'
        (Get-AzDevOpsPolicyAssessment @{ geography = 'Australia' } $rule $policy).Outcome | Should -Be 'Fail'
        (Get-AzDevOpsPolicyAssessment @{} $rule $policy).Outcome | Should -Be 'Unknown'
    }
    It 'accepts an explicit disabled billing setting' {
        $rule = 'Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured'
        $policy = @{ Reference = 'billing-v1'; Expected = $false }
        (Get-AzDevOpsPolicyAssessment @{ isEnterpriseBillingEnabled = $false } $rule $policy).Outcome | Should -Be 'Pass'
        (Get-AzDevOpsPolicyAssessment @{ isEnterpriseBillingEnabled = $true } $rule $policy).Outcome | Should -Be 'Fail'
    }
    It 'accepts approved SSH and OAuth access' {
        foreach ($suffix in 'DisallowSecureShell', 'DisallowOAuthAuthentication') {
            $field = 'policy.' + $suffix.Substring(0, 1).ToLower() + $suffix.Substring(1)
            $target = @{ $field = $false }
            (Get-AzDevOpsPolicyAssessment $target "Azure.DevOps.Organization.Security.Policies.$suffix" @{ Reference = 'auth-v1'; Expected = $false }).Outcome | Should -Be 'Pass'
        }
    }
    It 'requires reviewed guest evidence and rejects unapproved guests' {
        $rule = 'Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess'
        $policy = @{ Reference = 'collaboration-v1'; Expected = $false; ApprovedGuests = @('guest-a'); ApprovedGuestReviews = @('guest-review-v1') }
        $target = @{ 'policy.disallowAadGuestUserAccess' = $false }
        (Get-AzDevOpsPolicyAssessment $target $rule $policy).Outcome | Should -Be 'Unknown'
        $target.GuestAccessEvidence = @{ Status = 'Complete'; Reference = 'guest-review-v1'; Guests = @(@{ Descriptor = 'guest-a' }) }
        (Get-AzDevOpsPolicyAssessment $target $rule $policy).Outcome | Should -Be 'Pass'
        $target.GuestAccessEvidence.Guests += @{ Descriptor = 'guest-b' }
        (Get-AzDevOpsPolicyAssessment $target $rule $policy).ReasonCode | Should -Be 'UnapprovedGuestAccess'
    }
    It 'requires a reference for an explicit policy and honors target scope' {
        $rule = 'Azure.DevOps.Repos.License'
        (Get-AzDevOpsPolicyAssessment @{ LicenseExists = $true } $rule @{}).Outcome | Should -Be 'Unknown'
        (Get-AzDevOpsPolicyAssessment @{ ObjectName = 'private-app' } $rule @{ Reference = 'distribution-v1'; Targets = @('published-library') }).Outcome | Should -Be 'NotApplicable'
    }
    It 'requires explicit approval for a public project' {
        $rule = 'Azure.DevOps.Project.Visibility'
        (Get-AzDevOpsPolicyAssessment @{ visibility = 'public' } $rule).Outcome | Should -Be 'Fail'
        (Get-AzDevOpsPolicyAssessment @{ visibility = 'public' } $rule @{ Reference = 'open-source-v1'; Expected = 'public' }).Outcome | Should -Be 'Pass'
    }
    It 'uses an approved retention threshold for the evidence class' {
        $target = @{ RetentionSettings = @{ purgeArtifacts = @{ value = 3 }; purgePullRequestRuns = @{ value = 14 } } }
        (Get-AzDevOpsPolicyAssessment $target 'Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays' @{ Reference = 'retention-v1'; Minimum = 3 }).Outcome | Should -Be 'Pass'
        (Get-AzDevOpsPolicyAssessment $target 'Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays' @{ Reference = 'audit-v1'; Minimum = 30 }).Outcome | Should -Be 'Fail'
    }
    It 'accepts approved floating images and rejects retired or unapproved images' {
        $rule = 'Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest'
        $policy = @{ Reference = 'image-lifecycle-v1'; AllowedImages = @('ubuntu-latest', 'ubuntu-22.04'); RetiredImages = @('ubuntu-22.04') }
        (Get-AzDevOpsPolicyAssessment @{ pool = @{ vmImage = 'ubuntu-latest' } } $rule $policy).Outcome | Should -Be 'Pass'
        (Get-AzDevOpsPolicyAssessment @{ stages = @(@{ jobs = @(@{ pool = @{ vmImage = 'ubuntu-22.04' } }) }) } $rule $policy).Outcome | Should -Be 'Fail'
        (Get-AzDevOpsPolicyAssessment @{ pool = @{ vmImage = 'unapproved' } } $rule $policy).Outcome | Should -Be 'Fail'
        (Get-AzDevOpsPolicyAssessment @{} $rule $policy).Outcome | Should -Be 'Unknown'
        (Get-AzDevOpsPolicyAssessment @{ pool = @{ vmImage = '$(dynamicImage)' } } $rule $policy).Outcome | Should -Be 'Unknown'
    }
    It 'accepts only approved, effective equivalent controls' {
        $rule = 'Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled'
        $policy = @{ Reference = 'scanning-v1'; ApprovedEquivalentControls = @('scanner-review-v1') }
        $target = @{ Ghas = @{ advSecEnabled = $false }; EquivalentControls = @(@{ RuleId = $rule; Reference = 'scanner-review-v1'; Effective = $true }) }
        (Get-AzDevOpsPolicyAssessment $target $rule $policy).ReasonCode | Should -Be 'ApprovedEquivalentControl'
        $target.EquivalentControls[0].Effective = $false
        (Get-AzDevOpsPolicyAssessment $target $rule $policy).Outcome | Should -Be 'Fail'
        $policy.Licensed = $false
        (Get-AzDevOpsPolicyAssessment $target $rule $policy).Outcome | Should -Be 'NotApplicable'
    }
    It 'distinguishes required human review from approved automation' {
        $rule = 'Azure.DevOps.Pipelines.Environments.ProductionHumanApproval'
        $target = @{ checks = @(@{ type = @{ name = 'InvokeRESTAPI' }; settings = @{} }) }
        $policy = @{ Reference = 'production-review-v1'; ApprovedEquivalentControls = @('automated-review-v1') }
        (Get-AzDevOpsPolicyAssessment $target $rule $policy).Outcome | Should -Be 'Fail'
        $target.EquivalentControls = @(@{ RuleId = $rule; Reference = 'automated-review-v1'; Effective = $true })
        (Get-AzDevOpsPolicyAssessment $target $rule $policy).Outcome | Should -Be 'Pass'
        $target.Remove('EquivalentControls')
        $target.checks = @(@{ type = @{ name = 'Approval' }; settings = @{ approvers = @(@{ id = 'synthetic-reviewer' }) } })
        (Get-AzDevOpsPolicyAssessment $target $rule $policy).Outcome | Should -Be 'Pass'
    }
    It 'applies optional policy configuration through the PSRule engine' {
        $rule = 'Azure.DevOps.Organization.GeneralOverview.TimeZoneSet'
        $targets = @(
            [pscustomobject]@{ ObjectType = 'Azure.DevOps.Organization.GeneralOverview'; ObjectName = 'approved'; timeZone = 'UTC' }
            [pscustomobject]@{ ObjectType = 'Azure.DevOps.Organization.GeneralOverview'; ObjectName = 'incorrect'; timeZone = 'CET' }
            [pscustomobject]@{ ObjectType = 'Azure.DevOps.Organization.GeneralOverview'; ObjectName = 'missing' }
        )
        $option = New-PSRuleOption -Configuration @{ assessmentPolicies = @{ $rule = @{ Reference = 'schedule-v1'; Expected = 'UTC' } } }
        $results = @($targets | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $rule -Option $option -Outcome All -Culture en -ErrorAction Stop)
        ($results | Where-Object TargetName -Like '*/approved').Outcome | Should -Be 'Pass'
        ($results | Where-Object TargetName -Like '*/incorrect').Outcome | Should -Be 'Fail'
        ($results | Where-Object TargetName -Like '*/missing').Outcome | Should -Be 'None'
    }
}
AfterAll { Remove-Module DevOpsTools.AzureDevOps.PSRule -Force }
