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
    $paths = New-LiveRuleTestData -ExportCommand Export-AzDevOpsProject -OutputPath (Join-Path $TestDrive 'exports')
    $outPath = $paths.FullAccess
    $outPathReadOnly = $paths.ReadOnly
    $outPathFineGrained = $paths.FineGrained

    
    # Run rules with default token type
    $ruleResult = Invoke-PSRule -InputPath "$($outPath)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en

    # Run rules with the public baseline
    $ruleResultPublic = Invoke-PSRule -InputPath "$($outPath)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en -Baseline Baseline.PublicProject


    # Run rules with ReadOnly token type
    $ruleResultReadOnly = Invoke-PSRule -InputPath "$($outPathReadOnly)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en


    # Run rules with FineGrained token type
    $ruleResultFineGrained = Invoke-PSRule -InputPath "$($outPathFineGrained)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en
}

Describe "Azure.DevOps.Project rules" -Tag 'Integration' {
    Context ' Azure.DevOps.Project.Visibility' {
        It " should pass once" {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.Visibility' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for ReadOnly token type" {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.Visibility' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for FineGrained token type" {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.Visibility' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should not be present in the PublicProject baseline" {
            $ruleHits = @($ruleResultPublic | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.Visibility' })
            $ruleHits.Count | Should -Be 0;
        }
    }

    Context ' Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers' {
        It " should pass once" {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for ReadOnly token type" {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for FineGrained token type" {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers' {
        It " should pass once" {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for ReadOnly token type" {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for FineGrained token type" {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Project.MainRepositoryAcl.ProjectValidUsers' {
        It " should fail once" {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainRepositoryAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It " should fail once for ReadOnly token type" {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainRepositoryAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for FineGrained token type" {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainRepositoryAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Fail';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Project.MainEnvironmentAcl.ProjectValidUsers' {
        It " should pass once" {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainEnvironmentAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for ReadOnly token type" {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainEnvironmentAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for FineGrained token type" {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainEnvironmentAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers' {
        It " should pass once" {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for ReadOnly token type" {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for FineGrained token type" {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }

    Context ' Azure.DevOps.Project.MainVariableGroupAcl.ProjectValidUsers' {
        It " should pass once" {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainVariableGroupAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for ReadOnly token type" {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainVariableGroupAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }

        It " should pass once for FineGrained token type" {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Project.MainVariableGroupAcl.ProjectValidUsers' })
            $ruleHits[0].Outcome | Should -Be 'Pass';
            $ruleHits.Count | Should -Be 1;
        }
    }
}
