BeforeAll {
    # Setup error handling
    $ErrorActionPreference = 'Stop';
    Set-StrictMode -Version latest;

    if ($Env:SYSTEM_DEBUG -eq 'true') {
        $VerbosePreference = 'Continue';
    }

    # Setup tests paths
    # $rootPath = $PWD;
    $rootPath = Split-Path -Path $PSScriptRoot -Parent
    $ourModule = (Join-Path -Path $rootPath -ChildPath 'src/DevOpsTools.AzureDevOps.Assessment')

    Import-Module -Name $ourModule -Force
    . "$PSScriptRoot/helpers/LiveRuleTestData.ps1"
    $paths = New-LiveRuleTestData -ExportCommand Export-AzDevOpsReposAndBranchPolicies -OutputPath (Join-Path $TestDrive 'exports')
    $outPath = $paths.FullAccess
    $outPathReadOnly = $paths.ReadOnly
    $outPathFineGrained = $paths.FineGrained

    
    # Run rules with default token type
    $ruleResult = Invoke-PSRule -InputPath "$($outPath)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en


    # Run rules with ReadOnly token type
    $ruleResultReadOnly = Invoke-PSRule -InputPath "$($outPathReadOnly)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en


    # Run rules with FineGrained token type
    $ruleResultFineGrained = Invoke-PSRule -InputPath "$($outPathFineGrained)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en
}

Describe "Azure.DevOps.Repos.Branch rules" -Tag 'Integration' {
    Context ' Azure.DevOps.Repos.Branch.HasBranchPolicy' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.HasBranchPolicy' -and $_.TargetName -like '*psrule-fail-project.refs/heads/fail-branch' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.HasBranchPolicy' -and $_.TargetName -like '*repository-success.refs/heads/main' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled' -and $_.TargetName -like '*psrule-fail-project.refs/heads/fail-branch' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled' -and $_.TargetName -like '*repository-success.refs/heads/main' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Repos.Branch.BranchPolicyMinimumReviewers' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyMinimumReviewers' -and $_.TargetName -like '*psrule-fail-project.refs/heads/fail-branch' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyMinimumReviewers' -and $_.TargetName -like '*repository-success.refs/heads/main' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Repos.Branch.BranchPolicyAllowSelfApproval' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyAllowSelfApproval' -and $_.TargetName -like '*psrule-fail-project.refs/heads/fail-branch' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass target named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyAllowSelfApproval' -and $_.TargetName -like '*repository-success.refs/heads/main' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Repos.Branch.BranchPolicyResetVotes' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyResetVotes' -and $_.TargetName -like '*psrule-fail-project.refs/heads/fail-branch' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass target named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyResetVotes' -and $_.TargetName -like '*repository-success.refs/heads/main' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Repos.Branch.BranchPolicyEnforceLinkedWorkItems' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyEnforceLinkedWorkItems' -and $_.TargetName -like '*psrule-fail-project.refs/heads/fail-branch' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyEnforceLinkedWorkItems' -and $_.TargetName -like '*repository-success.refs/heads/main' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Repos.Branch.BranchPolicyCommentResolution' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyCommentResolution' -and $_.TargetName -like '*psrule-fail-project.refs/heads/fail-branch' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyCommentResolution' -and $_.TargetName -like '*repository-success.refs/heads/main' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Repos.Branch.BranchPolicyMergeStrategy' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyMergeStrategy' -and $_.TargetName -like '*psrule-fail-project.refs/heads/fail-branch' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyMergeStrategy' -and $_.TargetName -like '*repository-success.refs/heads/main' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Repos.Branch.BranchPolicyRequireBuild' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyRequireBuild' -and $_.TargetName -like '*psrule-fail-project.refs/heads/fail-branch' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.BranchPolicyRequireBuild' -and $_.TargetName -like '*repository-success.refs/heads/main' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    # This rule is only checked for hits and not results as it is a pain to maintain at this time
    # The rule has been tested for results manually and is working as expected
    Context ' Azure.DevOps.Repos.Branch.CommitRecent' {
        It ' should hit for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.CommitRecent' -and $_.TargetName -like '*psrule-fail-project.refs/heads/fail-branch' })
            $ruleHits.Count | Should -Be 1;
        }

        It ' should hit for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Branch.CommitRecent' -and $_.TargetName -like '*repository-success.refs/heads/main' })
            $ruleHits.Count | Should -Be 1;
        }
    }
}
