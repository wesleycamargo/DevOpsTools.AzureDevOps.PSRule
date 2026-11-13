BeforeAll {
    Import-Module PSRule
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
    Add-Type -Path (Join-Path (Get-Module PSRule).ModuleBase 'YamlDotNet.dll')
    $deserializer = [YamlDotNet.Serialization.DeserializerBuilder]::new().Build()
    $pipeline = $deserializer.Deserialize([System.IO.StringReader]::new(
        (Get-Content "$PSScriptRoot/../pipelines/psrule-assessment.yml" -Raw)))
    $assessment = @($pipeline['steps'] | Where-Object { $_['displayName'] -eq 'Export and assess Azure DevOps organization' })[0]
    $assessmentScript = [scriptblock]::Create($assessment['inputs']['script'])
    $publish = @($pipeline['steps'] | Where-Object { $_['task'] -eq 'PublishBuildArtifacts@1' })[0]
}

Describe 'Azure DevOps assessment pipeline' -Tag 'Unit' {
    BeforeEach {
        $savedEnvironment = @{}
        $runPath = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $environment = @{
            KEEP_RESULTS = 'false'
            TZ = 'Etc/GMT-2'
            AGENT_TEMPDIRECTORY = Join-Path $runPath 'agent-temp'
            BUILD_ARTIFACTSTAGINGDIRECTORY = Join-Path $runPath 'artifacts'
            BUILD_SOURCEVERSION = 'synthetic-commit'
            BUILD_SOURCESDIRECTORY = (Resolve-Path "$PSScriptRoot/..").Path
            ADO_ORGANIZATION = 'fixture-org'
            ADO_ORGANIZATION_ID = '11111111-1111-1111-1111-111111111111'
            ADO_TENANT_ID = 'fixture-tenant'
            ADO_CLIENT_ID = 'fixture-client'
            ADO_CLIENT_SECRET = 'fixture-secret'
        }
        foreach ($name in $environment.Keys) {
            $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
            [Environment]::SetEnvironmentVariable($name, $environment[$name])
        }
        [TimeZoneInfo]::ClearCachedData()
        Mock Get-Date { [datetime]::new(2026, 11, 7, 14, 5, 42, [DateTimeKind]::Local) }
        $script:collectionStatus = 'Complete'
        $script:exportPaths = @()
        $results = @([pscustomobject]@{ RuleName = 'fixture'; Outcome = 'Pass' })
        Mock Import-Module {}
        Mock Invoke-RestMethod { [pscustomobject]@{ access_token = 'fixture-token' } }
        Mock Invoke-RestMethod { [pscustomobject]@{ instanceId = '22222222-2222-2222-2222-222222222222' } } -ParameterFilter { $Uri -eq 'https://dev.azure.com/fixture-org/_apis/connectionData' }
        Mock Connect-AzDevOps {}
        Mock Export-AzDevOpsOrganizationRuleData {
            param ($OutputPath, $CompletenessReportPath, [switch]$Strict)
            $script:exportPaths += $OutputPath
            @{ Status = $script:collectionStatus } | ConvertTo-Json | Set-Content $CompletenessReportPath
            if ($script:collectionStatus -ne 'Complete' -and $Strict) {
                throw 'Assessment collection is incomplete.'
            }
            $projectDirectory = Join-Path $OutputPath 'fixture-project'
            New-Item $projectDirectory -ItemType Directory -Force | Out-Null
            '{}' | Set-Content (Join-Path $projectDirectory 'fixture.prj.ado.json')
            '{}' | Set-Content (Join-Path $OutputPath 'organization.ado.json')
        }
        Mock Invoke-PSRule { [pscustomobject]@{ RuleName = 'fixture'; Outcome = 'None'; OutcomeReason = 'PreconditionFail' } }
        Mock Export-AzDevOpsAssessmentRun {
            param ($OutputPath, $HtmlOutputPath, $CollectionStatusPath)
            $report = [pscustomobject]@{
                SchemaVersion = 1; Organization = 'fixture-org'; SourceRevision = 'synthetic-commit'
                RuleSetVersion = 'fixture-rules'; SeverityPolicyVersion = 'fixture-severity'
                Baseline = 'Baseline.Default'; Projects = @()
            }
            $report | ConvertTo-Json | Set-Content -LiteralPath $OutputPath
            if ($HtmlOutputPath) {
                & (Get-Module DevOpsTools.AzureDevOps.PSRule) {
                    param($Report, $Status, $Output)
                    Export-AzDevOpsAssessmentHtmlReport -Assessment $Report -CollectionStatusPath $Status -OutputPath $Output
                } $report $CollectionStatusPath $HtmlOutputPath
            }
            return $report
        }
        Mock Assert-PSRule {
            param ($InputPath, $OutputPath, $ResultVariable)
            @((Get-ChildItem $InputPath -File).Name | Sort-Object) | Should -Be @('fixture.prj.ado.json', 'organization.ado.json')
            '{}' | Set-Content $OutputPath
            for ($scopeIndex = 1; $scopeIndex -le 8; $scopeIndex++) {
                $scopedResultVariable = Get-Variable -Scope $scopeIndex | Where-Object Name -EQ $ResultVariable
                if ($null -ne $scopedResultVariable) {
                    $scopedResultVariable.Value = @([pscustomobject]@{ Outcome = 'Pass' })
                    break
                }
            }
        }
    }

    AfterEach {
        foreach ($name in $savedEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name])
        }
        [TimeZoneInfo]::ClearCachedData()
    }

    It 'assesses complete exports and publishes only separate reports' {
        $retentionParameter = @($pipeline['parameters'] | Where-Object { $_['name'] -eq 'KeepResults' })[0]
        $retentionParameter['type'] | Should -Be 'boolean'
        $retentionParameter['default'] | Should -Be 'false'
        $assessment['env']['KEEP_RESULTS'] | Should -Be '${{ parameters.KeepResults }}'
        & $assessmentScript

        Should -Invoke Assert-PSRule -Times 1 -Exactly -ParameterFilter { @($InputPath).Count -eq 2 -and @($InputPath | Where-Object { $_ -like '*fixture-project*fixture.prj.ado.json' }).Count -eq 1 -and $Outcome -eq 'All' }
        Should -Invoke Export-AzDevOpsAssessmentRun -Times 1 -Exactly -ParameterFilter { $SourceRevision -eq 'synthetic-commit' -and $Organization -eq 'fixture-org' }
        $outputDirectory = @(Get-Item -LiteralPath (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'outputs'))
        $outputDirectory.Count | Should -Be 1
        $outputDirectory[0].FullName | Should -Be (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'outputs')
        (Get-Content (Join-Path $outputDirectory[0].FullName 'collection-status.json') -Raw | ConvertFrom-Json).Status | Should -Be 'Complete'
        Test-Path (Join-Path $outputDirectory[0].FullName 'psrule-results.sarif') | Should -BeTrue
        $script:exportPaths[0] | Should -Be (Join-Path $outputDirectory[0].FullName 'targets')
        $publish['inputs']['PathtoPublish'] | Should -Be '$(Build.ArtifactStagingDirectory)'
        @((Get-ChildItem $outputDirectory[0].FullName).Name | Sort-Object) | Should -Be @('assessment-results.json', 'collection-status.json', 'psrule-report.html', 'psrule-results.sarif', 'targets')
        Should -Invoke Export-AzDevOpsAssessmentRun -Times 1 -Exactly -ParameterFilter {
            $HtmlOutputPath -eq (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'outputs/psrule-report.html') -and
            $CollectionStatusPath -eq (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'outputs/collection-status.json')
        }
    }

    It 'projects detailed precondition outcomes rather than the assertion result subset' {
        & $assessmentScript

        Should -Invoke Invoke-PSRule -Times 1 -Exactly -ParameterFilter { $Outcome -eq 'All' -and @($InputPath).Count -eq 2 -and @($InputPath | Where-Object { $_ -like '*fixture-project*fixture.prj.ado.json' }).Count -eq 1 }
        Should -Invoke Export-AzDevOpsAssessmentRun -Times 1 -Exactly -ParameterFilter { $Result.Count -eq 1 -and $Result[0].Outcome -eq 'None' }
    }

    It 'uses the authenticated organization identity instead of a stale configured ID' {
        & $assessmentScript

        Should -Invoke Connect-AzDevOps -Times 1 -Exactly -ParameterFilter { $OrganizationId -eq '22222222-2222-2222-2222-222222222222' }
        Should -Invoke Export-AzDevOpsOrganizationRuleData -Times 1 -Exactly -ParameterFilter { $OrganizationId -eq '22222222-2222-2222-2222-222222222222' }
    }

    It 'stops before collection when organization identity is unavailable' {
        $previous = Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'outputs/collection-status.json'
        New-Item (Split-Path $previous -Parent) -ItemType Directory -Force | Out-Null
        'previous-evidence' | Set-Content $previous
        Mock Invoke-RestMethod { [pscustomobject]@{} } -ParameterFilter { $Uri -eq 'https://dev.azure.com/fixture-org/_apis/connectionData' }

        { & $assessmentScript } | Should -Throw '*did not return an organization identity*'

        Should -Invoke Export-AzDevOpsOrganizationRuleData -Times 0 -Exactly
        (Get-Content $previous -Raw).Trim() | Should -Be 'previous-evidence'
    }

    It 'stops incomplete assessment while allowing partial pipeline success and retaining its report' {
        $script:collectionStatus = 'Partial'

        { & $assessmentScript } | Should -Throw '*collection is incomplete*'

        Should -Invoke Assert-PSRule -Times 0 -Exactly
        $outputDirectory = @(Get-Item -LiteralPath (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'outputs'))
        $outputDirectory.Count | Should -Be 1
        (Get-Content (Join-Path $outputDirectory[0].FullName 'collection-status.json') -Raw | ConvertFrom-Json).Status | Should -Be 'Partial'
        Test-Path (Join-Path $outputDirectory[0].FullName 'psrule-results.sarif') | Should -BeFalse
        $assessment['continueOnError'] | Should -BeTrue
        $publish['condition'] | Should -Be 'always()'
    }

    It 'allows partial pipeline success when rule assertions fail' {
        Mock Assert-PSRule { throw 'fixture rule assertion failure' }

        { & $assessmentScript } | Should -Throw '*rule assertion failure*'

        Should -Invoke Assert-PSRule -Times 1 -Exactly
        $outputDirectory = @(Get-Item -LiteralPath (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'outputs'))
        $outputDirectory.Count | Should -Be 1
        (Get-Content (Join-Path $outputDirectory[0].FullName 'collection-status.json') -Raw | ConvertFrom-Json).Status | Should -Be 'Complete'
        $assessment['continueOnError'] | Should -BeTrue
        $publish['condition'] | Should -Be 'always()'
    }

    It 'rejects an assessment that evaluates no rule results' {
        Mock Assert-PSRule { param($ResultVariable) Set-Variable -Name $ResultVariable -Scope 1 -Value @() }
        { & $assessmentScript } | Should -Throw '*zero rule results*'
    }

    It 'retains HTML before surfacing noncompliant rule results' {
        Mock Assert-PSRule {
            param ($OutputPath, $ResultVariable)
            '{}' | Set-Content -LiteralPath $OutputPath
            for ($scopeIndex = 1; $scopeIndex -le 8; $scopeIndex++) {
                $scopedResultVariable = Get-Variable -Scope $scopeIndex | Where-Object Name -EQ $ResultVariable
                if ($null -ne $scopedResultVariable) {
                    $scopedResultVariable.Value = @([pscustomobject]@{ Outcome = 'Fail' })
                    break
                }
            }
            Write-Error 'Fixture noncompliant rule result.' -ErrorId 'PSRule.Fail' -ErrorAction Continue
        }

        { & $assessmentScript } | Should -Throw '*PSRule reported failures or errors*'

        $output = Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'outputs'
        Test-Path -LiteralPath (Join-Path $output 'psrule-report.html') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $output 'assessment-results.json') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $output 'psrule-results.sarif') | Should -BeTrue
        Should -Invoke Export-AzDevOpsAssessmentRun -Times 1 -Exactly
        $assessment['continueOnError'] | Should -BeTrue
        $publish['condition'] | Should -Be 'always()'
    }

    It 'rejects a same-minute repeated retained run without deleting assessment evidence' {
        $env:KEEP_RESULTS = 'true'
        & $assessmentScript
        $expectedRun = Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'outputs/2026-11-07-14-05'
        $stalePath = Join-Path $script:exportPaths[0] 'stale.prj.ado.json'
        'stale-evidence' | Set-Content $stalePath
        $statusPath = Join-Path (Split-Path $script:exportPaths[0] -Parent) 'collection-status.json'
        $statusBefore = Get-Content $statusPath -Raw

        { & $assessmentScript } | Should -Throw '*already exists*'

        $script:exportPaths | Should -Be @(Join-Path $expectedRun 'targets')
        Get-Content $stalePath -Raw | Should -Be "stale-evidence`n"
        Get-Content $statusPath -Raw | Should -Be $statusBefore
        Should -Invoke Export-AzDevOpsOrganizationRuleData -Times 1 -Exactly
        Should -Invoke Assert-PSRule -Times 1 -Exactly
        Should -Invoke Invoke-PSRule -Times 1 -Exactly
        Should -Invoke Export-AzDevOpsAssessmentRun -Times 1 -Exactly
    }
    It 'replaces current evidence on repeated default runs without evaluating stale targets' {
        & $assessmentScript
        $stale = Join-Path $script:exportPaths[0] 'stale.ado.json'
        '{}' | Set-Content $stale
        & $assessmentScript
        Test-Path $stale | Should -BeFalse
        $script:exportPaths | Should -Be @((Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'outputs/targets'), (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'outputs/targets'))
        Should -Invoke Assert-PSRule -Times 2 -Exactly
    }


    It 'scopes the assessment output lock in a finally block' {
        $assessment['inputs']['script'] | Should -Match '(?s)\$runLock\s*=\s*Initialize-AzDevOpsAssessmentRunDirectory.*finally\s*\{.*Release-AzDevOpsAssessmentRunLock\s+-RunLock\s+\$runLock'
    }

    It 'does not publish stale HTML after incomplete recollection' {
        & $assessmentScript
        $html = Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'outputs/psrule-report.html'
        Test-Path -LiteralPath $html | Should -BeTrue
        $script:collectionStatus = 'Partial'
        { & $assessmentScript } | Should -Throw '*collection is incomplete*'
        Test-Path -LiteralPath $html | Should -BeFalse
        Should -Invoke Export-AzDevOpsAssessmentRun -Times 1 -Exactly
        $publish['condition'] | Should -Be 'always()'
    }

}
