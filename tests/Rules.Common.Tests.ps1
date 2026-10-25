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

    Import-Module -Name $ourModule -Force;
}

Describe "DevOpsTools.AzureDevOps.Assessment Rules" -Tag 'Unit' {
    Context ' Base rules' {
        It ' should contain 119 rules' {
            $rules = Get-PSRule -Module DevOpsTools.AzureDevOps.Assessment
            $rules.Count | Should -Be 119
        }

        It ' should contain a markdown help file for each rule' {
            $rules = Get-PSRule -Module DevOpsTools.AzureDevOps.Assessment
            $rules | ForEach-Object {
                $helpFile = Join-Path -Path "$ourModule/en" -ChildPath "$($_.Name).md"
                Test-Path -Path $helpFile | Should -Be $true
            }
        }
    }

    Context 'Rule Loading' {
        It ' should load all 24 organization pipeline settings rules' {
            $rules = Get-PSRule -Module DevOpsTools.AzureDevOps.Assessment
            $orgRules = $rules | Where-Object { $_.Name -like 'Azure.DevOps.Organization.Pipelines.Settings.*' }
            $orgRules.Count | Should -Be 24
            $orgRules | ForEach-Object { Write-Verbose "Loaded rule: $($_.Name)" }
        }
    }
}

Describe "Azure DevOps rule data exports" -Tag 'Integration' {
    BeforeAll {
        . "$PSScriptRoot/helpers/LiveRuleTestData.ps1"
        $paths = New-LiveRuleTestData -ExportCommand Export-AzDevOpsRuleData -OutputPath (Join-Path $TestDrive 'exports')
        $outPath = $paths.FullAccess
        $outPathReadOnly = $paths.ReadOnly
        $outPathFineGrained = $paths.FineGrained
    }

    It 'should export rule data for all three permission profiles' {
        foreach ($path in @($outPath, $outPathReadOnly, $outPathFineGrained)) {
            @(Get-ChildItem -Path $path -Filter '*.ado.json' -File).Count | Should -BeGreaterThan 0
        }
    }

    AfterAll {
        Disconnect-AzDevOps
    }
}

AfterAll {
    # Remove Module
    Disconnect-AzDevOps
    Remove-Module -Name DevOpsTools.AzureDevOps.Assessment -Force;
}
