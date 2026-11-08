BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Blocking branch policy evaluation' -Tag 'Unit' {
    It 'only accepts an enabled blocking <Case> policy' -ForEach @(
        @{ Case = 'minimum reviewers'; Name = 'BranchPolicyMinimumReviewers'; TypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'; Settings = @{ minimumApproverCount = 2 } }
        @{ Case = 'self-approval restriction'; Name = 'BranchPolicyAllowSelfApproval'; TypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'; Settings = @{ creatorVoteCounts = $false } }
        @{ Case = 'resetting votes'; Name = 'BranchPolicyResetVotes'; TypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'; Settings = @{ resetOnSourcePush = $true } }
        @{ Case = 'work item linking'; Name = 'BranchPolicyEnforceLinkedWorkItems'; TypeId = '40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e'; Settings = @{} }
        @{ Case = 'comment resolution'; Name = 'BranchPolicyCommentResolution'; TypeId = 'c6a1889d-b943-4856-b76f-9e46bb6b0df2'; Settings = @{} }
        @{ Case = 'merge strategy'; Name = 'BranchPolicyMergeStrategy'; TypeId = 'fa4e907d-c16b-4a4c-9dfa-4916e5d171ab'; Settings = @{ allowSquash = $true } }
        @{ Case = 'build validation'; Name = 'BranchPolicyRequireBuild'; TypeId = '0609b952-1397-4640-95ec-e00a01b2c241'; Settings = @{ buildDefinitionId = 42 } }
    ) {
        $policy = [pscustomobject]@{
            type = @{ id = $TypeId }
            isEnabled = $true
            isBlocking = $true
            settings = $Settings
        }
        $target = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.Repo.Branch'
            ObjectName = 'fixture.refs/heads/main'
            BranchPolicy = @($policy)
        }
        $ruleId = "Azure.DevOps.Repos.Branch.$Name"
        foreach ($scenario in @(
            @{ Enabled = $true; Blocking = $true; Expected = 'Pass' }
            @{ Enabled = $true; Blocking = $false; Expected = 'Fail' }
            @{ Enabled = $false; Blocking = $true; Expected = 'Fail' }
        )) {
            $policy.isEnabled = $scenario.Enabled
            $policy.isBlocking = $scenario.Blocking
            $results = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $ruleId -Culture en -ErrorAction Stop)
            $results.Count | Should -Be 1
            $results[0].Outcome | Should -Be $scenario.Expected
        }
    }

    It 'does not count an unrelated blocking policy as a required policy' {
        $target = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.Repo.Branch'
            ObjectName = 'fixture.refs/heads/main'
            BranchPolicy = @(@{ isEnabled = $true; isBlocking = $true; type = @{ id = 'other' }; settings = @{ minimumApproverCount = 2 } })
        }
        $result = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name 'Azure.DevOps.Repos.Branch.BranchPolicyMinimumReviewers' -Culture en)
        $result[0].Outcome | Should -Be 'Fail'
    }

    It 'distinguishes a configured policy from an enforced policy on branch and repository' {
        foreach ($test in @(
            @{ TargetType = 'Azure.DevOps.Repo.Branch'; Field = 'BranchPolicy'; Rule = 'Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled' }
            @{ TargetType = 'Azure.DevOps.Repo'; Field = 'MainBranchPolicy'; Rule = 'Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled' }
        )) {
            $target = [pscustomobject]@{ ObjectType = $test.TargetType; ObjectName = 'fixture' }
            $target | Add-Member -NotePropertyName $test.Field -NotePropertyValue @(
                @{ isEnabled = $true; isBlocking = $false; type = @{ id = 'fixture' } }
            )
            $result = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $test.Rule -Culture en)
            $result[0].Outcome | Should -Be 'Fail'
            $target.($test.Field)[0].isBlocking = $true
            $result = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $test.Rule -Culture en)
            $result[0].Outcome | Should -Be 'Pass'
        }
    }
}

AfterAll {
    Remove-Module DevOpsTools.AzureDevOps.PSRule -Force
}
