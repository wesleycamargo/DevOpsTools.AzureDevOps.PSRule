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
    $paths = New-LiveRuleTestData -ExportCommand Export-AzDevOpsRetentionSettings -OutputPath (Join-Path $TestDrive 'exports')
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

Describe "Azure.DevOps.RetentionSettings rules" -Tag 'Integration' {
    Context ' Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays' {
        It 'does not evaluate without the required referenced policy and evidence' {
            $allResults = @($ruleResult) + @($ruleResultFineGrained) + @($ruleResultReadOnly)
            @($allResults | Where-Object RuleName -EQ 'Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays').Count | Should -Be 0
        }

        It 'retains its English rule help' {
            Test-Path (Join-Path $ourModule 'en/Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays.md') | Should -Be $true
        }
    }

    Context ' Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays' {
        It 'does not evaluate without the required referenced policy and evidence' {
            $allResults = @($ruleResult) + @($ruleResultFineGrained) + @($ruleResultReadOnly)
            @($allResults | Where-Object RuleName -EQ 'Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays').Count | Should -Be 0
        }

        It 'retains its English rule help' {
            Test-Path (Join-Path $ourModule 'en/Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays.md') | Should -Be $true
        }
    }
}

AfterAll {
    # Remove Module
    Remove-Module -Name DevOpsTools.AzureDevOps.Assessment -Force
}
