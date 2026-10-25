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
    $paths = New-LiveRuleTestData -ExportCommand Export-AzDevOpsEnvironmentChecks -OutputPath (Join-Path $TestDrive 'exports')
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

Describe "Azure.DevOps.Pipelines.Environments rules" -Tag 'Integration' {
    Context ' Azure.DevOps.Pipelines.Environments.ProductionCheckProtection' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection' -and $_.TargetName -match 'production-fail$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should not be in the output for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection' -and $_.TargetName -match 'production-fail$' })
            $ruleHits.Count | Should -Be 0;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection' -and $_.TargetName -match 'success' })
            $ruleHits.Count | Should -Be 0;
        }

        It ' should have the same result as default for FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection' -and $_.TargetName -match 'production-fail$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Pipelines.Environments.ProductionCheckProtection.md');
            $fileExists | Should -Be $true;
        }
    }

    Context ' Azure.DevOps.Pipelines.Environments.ProductionHumanApproval' {
        It 'does not evaluate without the required referenced policy and evidence' {
            $allResults = @($ruleResult) + @($ruleResultFineGrained) + @($ruleResultReadOnly)
            @($allResults | Where-Object RuleName -EQ 'Azure.DevOps.Pipelines.Environments.ProductionHumanApproval').Count | Should -Be 0
        }

        It 'retains its English rule help' {
            Test-Path (Join-Path $ourModule 'en/Azure.DevOps.Pipelines.Environments.ProductionHumanApproval.md') | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Pipelines.Environments.Description' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.Description' -and $_.TargetName -match 'production-fail$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.Description' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should not be in the output for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.Description' -and $_.TargetName -match 'production-fail$' })
            $ruleHits.Count | Should -Be 0;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.Description' -and $_.TargetName -match 'success' })
            $ruleHits.Count | Should -Be 0;
        }

        It ' should have the same result as default for FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.Description' -and $_.TargetName -match 'production-fail$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.Description' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Pipelines.Environments.Description.md');
            $fileExists | Should -Be $true;
        }
    }

    Context ' Azure.DevOps.Pipelines.Environments.ProductionBranchLimit' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProductionBranchLimit' -and $_.TargetName -match 'production-fail$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProductionBranchLimit' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should not be in the output for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProductionBranchLimit' -and $_.TargetName -match 'production-fail$' })
            $ruleHits.Count | Should -Be 0;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProductionBranchLimit' -and $_.TargetName -match 'success' })
            $ruleHits.Count | Should -Be 0;
        }

        It ' should have the same result as default for FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProductionBranchLimit' -and $_.TargetName -match 'production-fail$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProductionBranchLimit' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Pipelines.Environments.ProductionBranchLimit.md');
            $fileExists | Should -Be $true;
        }
    }

    Context ' Azure.DevOps.Pipelines.Environments.InheritedPermissions' {
        It 'does not evaluate without the required referenced policy and evidence' {
            $allResults = @($ruleResult) + @($ruleResultFineGrained) + @($ruleResultReadOnly)
            @($allResults | Where-Object RuleName -EQ 'Azure.DevOps.Pipelines.Environments.InheritedPermissions').Count | Should -Be 0
        }

        It 'retains its English rule help' {
            Test-Path (Join-Path $ourModule 'en/Azure.DevOps.Pipelines.Environments.InheritedPermissions.md') | Should -Be $true
        }
    }

    Context 'Azure.DevOps.Pipelines.Environments.ProjectValidUsers' {
        It ' should fail for targets named fail' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProjectValidUsers' -and $_.TargetName -match 'production-fail$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should pass for targets named success' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProjectValidUsers' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should not be in the output for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProjectValidUsers' -and $_.TargetName -match 'production-fail$' })
            $ruleHits.Count | Should -Be 0;

            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProjectValidUsers' -and $_.TargetName -match 'success' })
            $ruleHits.Count | Should -Be 0;
        }

        It ' should have the same result as default for FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProjectValidUsers' -and $_.TargetName -match 'production-fail$' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;

            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Pipelines.Environments.ProjectValidUsers' -and $_.TargetName -match 'success' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Pipelines.Environments.ProjectValidUsers.md');
            $fileExists | Should -Be $true;
        }
    }
}

AfterAll {
    # Remove Module
    Remove-Module -Name DevOpsTools.AzureDevOps.Assessment -Force;
}
