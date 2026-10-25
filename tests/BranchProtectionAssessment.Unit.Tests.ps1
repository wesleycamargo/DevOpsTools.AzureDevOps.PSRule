BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.Assessment/DevOpsTools.AzureDevOps.Assessment.psd1" -Force
}
Describe 'Branch protection assessment acceptance' -Tag 'Unit' {
    It 'preserves missing, disabled, and insufficient policies for <Type>' -ForEach @(
        @{ Type = 'Azure.DevOps.Repo'; Field = 'MainBranchPolicy'; Exists = 'Azure.DevOps.Repos.HasDefaultBranchPolicy'; Enabled = 'Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled'; Reviewers = 'Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers' }
        @{ Type = 'Azure.DevOps.Repo.Branch'; Field = 'BranchPolicy'; Exists = 'Azure.DevOps.Repos.Branch.HasBranchPolicy'; Enabled = 'Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled'; Reviewers = 'Azure.DevOps.Repos.Branch.BranchPolicyMinimumReviewers' }
    ) {
        $target = [pscustomobject]@{ ObjectType = $Type; ObjectName = 'fixture' }
        $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name @($Exists, $Enabled) -Outcome All -Culture en -ErrorAction Stop)
        @($raw | Where-Object Outcome -EQ 'Fail').Count | Should -Be 2
        (ConvertTo-AzDevOpsAssessment $raw @($target) 'fixture/project').RiskObjectives.Count | Should -Be 1

        $policy = [pscustomobject]@{ isEnabled = $false; type = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }; settings = @{ minimumApproverCount = 0 } }
        $target | Add-Member -NotePropertyName $Field -NotePropertyValue @($policy)
        $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name @($Exists, $Enabled) -Outcome All -Culture en -ErrorAction Stop)
        ($raw | Where-Object RuleName -EQ $Exists).Outcome | Should -Be 'Pass'
        ($raw | Where-Object RuleName -EQ $Enabled).Outcome | Should -Be 'Fail'
        (ConvertTo-AzDevOpsAssessment $raw @($target) 'fixture/project').RiskObjectives.Count | Should -Be 1

        $policy.isEnabled = $true
        $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name @($Exists, $Enabled, $Reviewers) -Outcome All -Culture en -ErrorAction Stop)
        ($raw | Where-Object RuleName -EQ $Exists).Outcome | Should -Be 'Pass'
        ($raw | Where-Object RuleName -EQ $Enabled).Outcome | Should -Be 'Pass'
        ($raw | Where-Object RuleName -EQ $Reviewers).Outcome | Should -Be 'Fail'
        $report = ConvertTo-AzDevOpsAssessment $raw @($target) 'fixture/project'
        $report.Findings.Count | Should -Be 3
        $report.RiskObjectives.Count | Should -Be 2
        @($report.RiskObjectives | Where-Object Outcome -EQ 'Fail').Count | Should -Be 1
    }
}
AfterAll { Remove-Module DevOpsTools.AzureDevOps.Assessment -Force }
