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
    $noExtraLicenseBaselineResult = Invoke-PSRule -InputPath "$($outPath)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en -Baseline Baseline.NoExtraLicense


    # Run rules with ReadOnly token type
    $ruleResultReadOnly = Invoke-PSRule -InputPath "$($outPathReadOnly)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en


    # Run rules with FineGrained token type
    $ruleResultFineGrained = Invoke-PSRule -InputPath "$($outPathFineGrained)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en
}

Describe "Azure.DevOps.Repos rules" -Tag 'Integration' {
    Context ' Azure.DevOps.Repos.HasDefaultBranchPolicy' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.HasDefaultBranchPolicy' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.HasDefaultBranchPolicy' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.HasDefaultBranchPolicy' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.HasDefaultBranchPolicy' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.HasDefaultBranchPolicy' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.HasDefaultBranchPolicy' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Repos.HasDefaultBranchPolicy.md');
            $fileExists | Should -Be $true;
        }
    }

    Context ' Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled.md');
            $fileExists | Should -Be $true;
        }
    }

    Context ' Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers.md');
            $fileExists | Should -Be $true;
        }
    }

    Context ' Azure.DevOps.Repos.DefaultBranchPolicyAllowSelfApproval' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyAllowSelfApproval' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyAllowSelfApproval' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyAllowSelfApproval' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyAllowSelfApproval' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyAllowSelfApproval' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyAllowSelfApproval' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Repos.DefaultBranchPolicyAllowSelfApproval.md');
            $fileExists | Should -Be $true;
        }
    }

    Context ' Azure.DevOps.Repos.DefaultBranchPolicyResetVotes' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyResetVotes' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyResetVotes' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyResetVotes' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyResetVotes' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyResetVotes' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyResetVotes' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Repos.DefaultBranchPolicyResetVotes.md');
            $fileExists | Should -Be $true;
        }
    }

    Context ' Azure.DevOps.Repos.Readme' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Readme' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Readme' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Readme' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Readme' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Readme' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.Readme' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have a markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Repos.Readme.md');
            $fileExists | Should -Be $true;
        }
    }

    Context ' Azure.DevOps.Repos.License' {
        It 'does not evaluate without the required referenced policy and evidence' {
            $allResults = @($ruleResult) + @($ruleResultFineGrained) + @($ruleResultReadOnly)
            @($allResults | Where-Object RuleName -EQ 'Azure.DevOps.Repos.License').Count | Should -Be 0
        }

        It 'retains its English rule help' {
            Test-Path (Join-Path $ourModule 'en/Azure.DevOps.Repos.License.md') | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Repos.DefaultBranchPolicyEnforceLinkedWorkItems' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyEnforceLinkedWorkItems' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyEnforceLinkedWorkItems' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyEnforceLinkedWorkItems' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyEnforceLinkedWorkItems' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyEnforceLinkedWorkItems' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyEnforceLinkedWorkItems' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have a markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Repos.DefaultBranchPolicyEnforceLinkedWorkItems.md');
            $fileExists | Should -Be $true;
        }
    }

    Context ' Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have a markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution.md');
            $fileExists | Should -Be $true;
        }
    }

    Context ' Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy.md');
            $fileExists | Should -Be $true;
        }
    }

    Context ' Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled' {
        It 'does not evaluate without the required referenced policy and evidence' {
            $allResults = @($ruleResult) + @($ruleResultFineGrained) + @($ruleResultReadOnly)
            @($allResults | Where-Object RuleName -EQ 'Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled').Count | Should -Be 0
        }

        It 'retains its English rule help' {
            Test-Path (Join-Path $ourModule 'en/Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled.md') | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes' {
        It 'does not evaluate without the required referenced policy and evidence' {
            $allResults = @($ruleResult) + @($ruleResultFineGrained) + @($ruleResultReadOnly)
            @($allResults | Where-Object RuleName -EQ 'Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes').Count | Should -Be 0
        }

        It 'retains its English rule help' {
            Test-Path (Join-Path $ourModule 'en/Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes.md') | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Repos.InheritedPermissions' {
        It 'does not evaluate without the required referenced policy and evidence' {
            $allResults = @($ruleResult) + @($ruleResultFineGrained) + @($ruleResultReadOnly)
            @($allResults | Where-Object RuleName -EQ 'Azure.DevOps.Repos.InheritedPermissions').Count | Should -Be 0
        }

        It 'retains its English rule help' {
            Test-Path (Join-Path $ourModule 'en/Azure.DevOps.Repos.InheritedPermissions.md') | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should be the same with a FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have a markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild.md');
            $fileExists | Should -Be $true;
        }
    }

    Context 'Azure.DevOps.Repos.ProjectValidUsers' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.ProjectValidUsers' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.ProjectValidUsers' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should not be present with the ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.ProjectValidUsers' })
            $ruleHits.Count | Should -Be 0;
        }

        It ' should be the same as default with a FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.ProjectValidUsers' -and $_.TargetName -match 'fail-project$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Repos.ProjectValidUsers' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have a markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Repos.ProjectValidUsers.md');
            $fileExists | Should -Be $true;
        }
    }
}

AfterAll {
    Remove-Module -Name DevOpsTools.AzureDevOps.Assessment -Force
}