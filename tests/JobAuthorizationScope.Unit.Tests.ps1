BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Independent organization job authorization settings' -Tag 'Unit' {
    It 'evaluates non-release=<NonRelease> and release=<Release> independently' -ForEach @(
        @{ NonRelease = $true; Release = $false; NonReleaseOutcome = 'Pass'; ReleaseOutcome = 'Fail' }
        @{ NonRelease = $false; Release = $true; NonReleaseOutcome = 'Fail'; ReleaseOutcome = 'Pass' }
        @{ NonRelease = $true; Release = $true; NonReleaseOutcome = 'Pass'; ReleaseOutcome = 'Pass' }
        @{ NonRelease = $false; Release = $false; NonReleaseOutcome = 'Fail'; ReleaseOutcome = 'Fail' }
    ) {
        $fixture = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.Organization.Pipelines.Settings'
            ObjectName = 'fixture.independent-job-scope'
            enforceJobAuthScope = $NonRelease
            enforceJobAuthScopeForReleases = $Release
        }
        $prefix = 'Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScope'
        $results = @($fixture | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name @(
            "${prefix}NonRelease", "${prefix}Release"
        ) -Culture en)
        $results.Count | Should -Be 2
        ($results | Where-Object RuleName -EQ "${prefix}NonRelease").Outcome | Should -Be $NonReleaseOutcome
        ($results | Where-Object RuleName -EQ "${prefix}Release").Outcome | Should -Be $ReleaseOutcome
    }
}

AfterAll {
    Remove-Module DevOpsTools.AzureDevOps.PSRule -Force
}
