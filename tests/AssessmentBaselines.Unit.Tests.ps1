BeforeAll {
    Import-Module "$PSScriptRoot/../src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psd1" -Force
}
Describe 'Assessment baseline compatibility' -Tag 'Unit' {
    It 'discovers the exact <Domain> review selection' -ForEach @(
        @{ Domain = 'Security' }; @{ Domain = 'Engineering' }; @{ Domain = 'Governance' }; @{ Domain = 'Conditional' }
    ) {
        $catalog = Get-AzDevOpsAssessmentCatalog
        $expected = @($catalog.Rules | Where-Object {
            -not $_.DeprecatedAlias -and (
                ($Domain -eq 'Conditional' -and $_.Applicability -eq 'Policy') -or
                ($Domain -ne 'Conditional' -and $_.Applicability -ne 'Policy' -and $_.Domain -eq $Domain)
            )
        } | Select-Object -ExpandProperty RuleId)
        $actual = @(Get-PSRule -Module PSRule.Rules.AzureDevOps -Baseline "PSRule.Rules.AzureDevOps\Baseline.${Domain}Review" -Culture en)
        $actual.Count | Should -Be $expected.Count
        @(Compare-Object $expected @($actual.RuleName)).Count | Should -Be 0
    }
    It 'retains every historical source rule identity' {
        $inventory = Get-Content "$PSScriptRoot/../docs/assessment/source-inventory.json" -Raw | ConvertFrom-Json
        $actual = @(Get-PSRule -Module PSRule.Rules.AzureDevOps -Culture en)
        @(Compare-Object @($inventory.rules.ruleId) @($actual.RuleName)).Count | Should -Be 0
    }
    It 'keeps licensed features excluded by NoExtraLicense' {
        $actual = @(Get-PSRule -Module PSRule.Rules.AzureDevOps -Baseline 'PSRule.Rules.AzureDevOps\Baseline.NoExtraLicense' -Culture en)
        $actual.RuleName | Should -Not -Contain 'Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled'
        $actual.RuleName | Should -Not -Contain 'Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes'
    }
    It 'allows only the explicit PublicProject baseline to exclude public exposure controls' {
        $actual = @(Get-PSRule -Module PSRule.Rules.AzureDevOps -Baseline 'PSRule.Rules.AzureDevOps\Baseline.PublicProject' -Culture en)
        foreach ($rule in 'Azure.DevOps.Project.Visibility', 'Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess', 'Azure.DevOps.Pipelines.Settings.StatusBadgesPrivate', 'Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess') {
            $actual.RuleName | Should -Not -Contain $rule
        }
        $rule = 'Azure.DevOps.Project.Visibility'
        $policy = @{ Reference = 'open-source-project-approval'; Targets = @('approved'); Expected = 'public' }
        (Get-AzDevOpsPolicyAssessment @{ ObjectName = 'confidential'; visibility = 'public' } $rule $policy).Outcome | Should -Be 'Fail'
        (Get-AzDevOpsPolicyAssessment @{ ObjectName = 'approved'; visibility = 'public' } $rule $policy).Outcome | Should -Be 'Pass'
    }
}
AfterAll { Remove-Module PSRule.Rules.AzureDevOps -Force }
