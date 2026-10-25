BeforeAll {
    # Setup error handling
    $ErrorActionPreference = 'Stop';
    Set-StrictMode -Version latest;

    if ($Env:SYSTEM_DEBUG -eq 'true') {
        $VerbosePreference = 'Continue';
    }

    # Setup tests paths
    $rootPath = Split-Path -Path $PSScriptRoot -Parent
    $ourModule = (Join-Path -Path $rootPath -ChildPath 'src/DevOpsTools.AzureDevOps.Assessment')

    Write-Verbose "Loading module from $ourModule"
    Import-Module -Name $ourModule -Force -ErrorAction Stop
    . "$PSScriptRoot/helpers/LiveRuleTestData.ps1"
    $paths = New-LiveRuleTestData -ExportCommand Export-AdoOrganizationPipelinesSettings -OutputPath (Join-Path $TestDrive 'exports')
    $outPath = $paths.FullAccess
    $outPathReadOnly = $paths.ReadOnly
    $outPathFineGrained = $paths.FineGrained

    # Verify OrganizationpipelineSettings.ado.json exists in each directory
    $jsonFile = 'OrganizationpipelineSettings.ado.json'
    foreach ($path in @($outPath, $outPathReadOnly, $outPathFineGrained)) {
        $jsonPath = Join-Path -Path $path -ChildPath $jsonFile
        if (-not (Test-Path -Path $jsonPath)) {
            throw "JSON file $jsonFile not found in $path"
        }
        # Validate JSON content
        try {
            $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
            if ($jsonContent.ObjectType -ne 'Azure.DevOps.Organization.Pipelines.Settings') {
                throw "Invalid ObjectType in $jsonPath. Expected 'Azure.DevOps.Organization.Pipelines.Settings', found '$($jsonContent.ObjectType)'"
            }
        }
        catch {
            throw "Failed to parse JSON in $jsonPath : $($_.Exception.Message)"
        }
    }

    # Run rules with default token type
    Write-Verbose "Running PSRule for default token type in $outPath"
    $ruleResult = Invoke-PSRule -InputPath "$($outPath)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en -ErrorAction Stop

    # Run rules with the public baseline
    Write-Verbose "Running PSRule for public baseline in $outPath"
    $ruleResultPublic = Invoke-PSRule -InputPath "$($outPath)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en -Baseline Baseline.PublicProject -ErrorAction Stop

    # Run rules with ReadOnly token type
    Write-Verbose "Running PSRule for ReadOnly token type in $outPathReadOnly"
    $ruleResultReadOnly = Invoke-PSRule -InputPath "$($outPathReadOnly)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en -ErrorAction Stop

    # Run rules with FineGrained token type
    Write-Verbose "Running PSRule for FineGrained token type in $outPathFineGrained"
    $ruleResultFineGrained = Invoke-PSRule -InputPath "$($outPathFineGrained)/" -Module DevOpsTools.AzureDevOps.Assessment -Format Detect -Culture en -ErrorAction Stop
}

Describe "Azure.DevOps.Organization.Pipelines.Settings rules" -Tag 'Integration' {
    Context 'JSON Input Validation' {
        It ' should have valid pipelineSettings.ado.json in out directory' {
            $jsonPath = Join-Path -Path $outPath -ChildPath 'OrganizationpipelineSettings.ado.json'
            $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
            $jsonContent.ObjectType | Should -Be 'Azure.DevOps.Organization.Pipelines.Settings'
            foreach ($property in @('statusBadgesArePrivate', 'enforceSettableVar', 'enforceJobAuthScope', 'enforceJobAuthScopeForReleases', 'enforceReferencedRepoScopedToken', 'disableClassicBuildPipelineCreation', 'disableClassicReleasePipelineCreation', 'forkProtectionEnabled', 'buildsEnabledForForks', 'enableShellTasksArgsSanitizing')) {
                $jsonContent.PSObject.Properties.Name | Should -Contain $property
            }
        }
    }

    Context ' Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess' {
        It ' should Pass' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for DisableAnonymousBadgeAccess"
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess.md')
            $fileExists | Should -Be $true
        }

        It ' should not be present in the PublicProject baseline' {
            $ruleHits = @($ruleResultPublic | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess' })
            $ruleHits.Count | Should -Be 0
        }
    }

    Context ' Azure.DevOps.Organization.Pipelines.Settings.LimitSettableVariables' {
        It ' should Pass' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.LimitSettableVariables' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for LimitSettableVariables"
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.LimitSettableVariables' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.LimitSettableVariables' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Pipelines.Settings.LimitSettableVariables.md')
            $fileExists | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeNonRelease' {
        It ' should Pass' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeNonRelease' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for LimitJobAuthScopeNonRelease"
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeNonRelease' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeNonRelease' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeNonRelease.md')
            $fileExists | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeRelease' {
        It ' should Pass' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeRelease' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for LimitJobAuthScopeRelease"
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeRelease' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeRelease' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeRelease.md')
            $fileExists | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Organization.Pipelines.Settings.ProtectRepoAccessInYaml' {
        It ' should Pass' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.ProtectRepoAccessInYaml' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for ProtectRepoAccessInYaml"
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.ProtectRepoAccessInYaml' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.ProtectRepoAccessInYaml' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Pipelines.Settings.ProtectRepoAccessInYaml.md')
            $fileExists | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Organization.Pipelines.Settings.DisableClassicBuildPipelines' {
        It ' should Pass' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableClassicBuildPipelines' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for DisableClassicBuildPipelines"
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableClassicBuildPipelines' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableClassicBuildPipelines' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Pipelines.Settings.DisableClassicBuildPipelines.md')
            $fileExists | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Organization.Pipelines.Settings.DisableClassicReleasePipelines' {
        It ' should Pass' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableClassicReleasePipelines' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for DisableClassicReleasePipelines"
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableClassicReleasePipelines' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableClassicReleasePipelines' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Pipelines.Settings.DisableClassicReleasePipelines.md')
            $fileExists | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Organization.Pipelines.Settings.LimitPRsFromForks' {
        It ' should Pass' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.LimitPRsFromForks' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for LimitPRsFromForks"
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.LimitPRsFromForks' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.LimitPRsFromForks' })
            $ruleHits[0].Outcome | Should -Be 'Pass'
            $ruleHits.Count | Should -Be 1
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Pipelines.Settings.LimitPRsFromForks.md')
            $fileExists | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Organization.Pipelines.Settings.DisableBuildsFromForks' {
        It ' should Fail' {
            # Note: This rule fails because buildsEnabledForForks is true in the organization settings.
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableBuildsFromForks' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for DisableBuildsFromForks"
            $ruleHits[0].Outcome | Should -Be 'Fail'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableBuildsFromForks' })
            $ruleHits[0].Outcome | Should -Be 'Fail'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.DisableBuildsFromForks' })
            $ruleHits[0].Outcome | Should -Be 'Fail'
            $ruleHits.Count | Should -Be 1
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Pipelines.Settings.DisableBuildsFromForks.md')
            $fileExists | Should -Be $true
        }
    }

    Context ' Azure.DevOps.Organization.Pipelines.Settings.SanitizeShellTaskArguments' {
        It ' should Fail' {
            # Note: This rule fails because enableShellTasksArgsSanitizing is false in the organization settings.
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.SanitizeShellTaskArguments' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for SanitizeShellTaskArguments"
            $ruleHits[0].Outcome | Should -Be 'Fail'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.SanitizeShellTaskArguments' })
            $ruleHits[0].Outcome | Should -Be 'Fail'
            $ruleHits.Count | Should -Be 1
        }

        It ' should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Pipelines.Settings.SanitizeShellTaskArguments' })
            $ruleHits[0].Outcome | Should -Be 'Fail'
            $ruleHits.Count | Should -Be 1
        }

        It ' should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Pipelines.Settings.SanitizeShellTaskArguments.md')
            $fileExists | Should -Be $true
        }
    }
}

AfterAll {
    # Remove Module
    Remove-Module -Name DevOpsTools.AzureDevOps.Assessment -Force;
}