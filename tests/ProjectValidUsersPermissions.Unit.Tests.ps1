BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Project Valid Users direct permission assessment' -Tag 'Unit' {
    BeforeEach {
        $rule = 'Azure.DevOps.Pipelines.Core.ProjectValidUsers'
        $policy = @{ Reference = 'reviewed-pipeline-namespace-v1'; SensitiveMask = 4; ApprovedMask = 0 }
        $acl = @{ acesDictionary = @{
            broad = @{ descriptor = 'S-1-9-999-0-0-0-0-3'; allow = 1; deny = 0 }
            other = @{ descriptor = 'S-1-9-999-0-0-0-0-7'; allow = 5; deny = 0 }
        } }
        $target = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.Pipeline'
            ObjectName = 'fixture.pipeline'
            Acls = @($acl)
        }
    }

    It 'accepts harmless direct access and ignores other groups' {
        (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $target -RuleId $rule -Policy $policy).Outcome | Should -Be 'Pass'
    }
    It 'fails when a sensitive grant is allowed to every valid project user' {
        $acl.acesDictionary.broad.allow = 5
        (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $target -RuleId $rule -Policy $policy).Outcome | Should -Be 'Fail'
    }
    It 'honors denied sensitive permissions and approved exceptions' {
        $acl.acesDictionary.broad.allow = 5
        $acl.acesDictionary.broad.deny = 4
        (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $target -RuleId $rule -Policy $policy).Outcome | Should -Be 'Pass'
        $acl.acesDictionary.broad.deny = 0
        $policy.ApprovedMask = 4
        (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $target -RuleId $rule -Policy $policy).Outcome | Should -Be 'Pass'
    }
    It 'requires policy, complete masks and usable ACL evidence' {
        (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $target -RuleId $rule -Policy $null).Outcome | Should -Be 'Unknown'
        $acl.acesDictionary.broad.Remove('deny')
        (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $target -RuleId $rule -Policy $policy).Outcome | Should -Be 'Unknown'
        $target.Acls = @()
        (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $target -RuleId $rule -Policy $policy).Outcome | Should -Be 'Unknown'
    }
    It 'selects the correct project-level namespace ACL' {
        $projectRule = 'Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers'
        $project = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.Project'
            ObjectName = 'fixture.project'
            ProjectAcls = @{ Pipelines = @($acl); Repositories = @(@{ acesDictionary = @{ broad = @{ descriptor = 'S-1-9-999-0-0-0-0-3'; allow = 5; deny = 0 } } }) }
        }
        (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $project -RuleId $projectRule -Policy $policy).Outcome | Should -Be 'Pass'
    }
    It 'evaluates the original rule ID using a referenced policy' {
        $acl.acesDictionary.broad.allow = 5
        $config = @{ projectValidUsersPolicies = @{
            'Azure.DevOps.Pipelines.Core.ProjectValidUsers' = $policy
        } }
        $opt = New-PSRuleOption -Configuration $config
        $results = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $rule -Option $opt -Culture en -ErrorAction Stop)
        $results.Count | Should -Be 1
        $results[0].Outcome | Should -Be 'Fail'
    }
    It 'reports skipped direct-permission assessment as Unknown rather than NotApplicable' {
        $raw = [pscustomobject]@{
            RuleName = $rule
            TargetType = $target.ObjectType
            TargetName = "$($target.ObjectType)/$($target.ObjectName)"
            Outcome = 'None'; OutcomeReason = ''; Reason = @()
        }
        $report = ConvertTo-AzDevOpsAssessment @($raw) @($target) 'fixture/project'
        $report.Findings.Count | Should -Be 1
        $report.Findings[0].Outcome | Should -Be 'Unknown'
    }
}

AfterAll {
    Remove-Module DevOpsTools.AzureDevOps.PSRule -Force
}
