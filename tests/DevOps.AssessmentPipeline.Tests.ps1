BeforeAll {
    Import-Module PSRule
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.Assessment/DevOpsTools.AzureDevOps.Assessment.psd1" -Force
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
            param ($OutputPath)
            @{ RuleSetVersion = '2026.10.21.2'; SeverityPolicyVersion = '1.1.0'; Projects = @() } | ConvertTo-Json | Set-Content $OutputPath
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
    }

    It 'assesses complete exports and publishes only separate reports' {
        & $assessmentScript

        Should -Invoke Assert-PSRule -Times 1 -Exactly -ParameterFilter { @($InputPath).Count -eq 2 -and @($InputPath | Where-Object { $_ -like '*fixture-project*fixture.prj.ado.json' }).Count -eq 1 -and $Outcome -eq 'All' }
        Should -Invoke Export-AzDevOpsAssessmentRun -Times 1 -Exactly -ParameterFilter { $SourceRevision -eq 'synthetic-commit' -and $Organization -eq 'fixture-org' }
        (Get-Content (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'collection-status.json') -Raw | ConvertFrom-Json).Status | Should -Be 'Complete'
        Test-Path (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'psrule-results.sarif') | Should -BeTrue
        $script:exportPaths[0].StartsWith($env:AGENT_TEMPDIRECTORY) | Should -BeTrue
        $publish['inputs']['PathtoPublish'] | Should -Be '$(Build.ArtifactStagingDirectory)'
        @((Get-ChildItem $env:BUILD_ARTIFACTSTAGINGDIRECTORY).Name) | Should -Be @('assessment-results.json', 'collection-status.json', 'psrule-results.sarif')
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
        Mock Invoke-RestMethod { [pscustomobject]@{} } -ParameterFilter { $Uri -eq 'https://dev.azure.com/fixture-org/_apis/connectionData' }

        { & $assessmentScript } | Should -Throw '*did not return an organization identity*'

        Should -Invoke Export-AzDevOpsOrganizationRuleData -Times 0 -Exactly
    }

    It 'stops incomplete assessment while allowing partial pipeline success and retaining its report' {
        $script:collectionStatus = 'Partial'

        { & $assessmentScript } | Should -Throw '*collection is incomplete*'

        Should -Invoke Assert-PSRule -Times 0 -Exactly
        (Get-Content (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'collection-status.json') -Raw | ConvertFrom-Json).Status | Should -Be 'Partial'
        Test-Path (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'psrule-results.sarif') | Should -BeFalse
        $assessment['continueOnError'] | Should -BeTrue
        $publish['condition'] | Should -Be 'always()'
    }

    It 'allows partial pipeline success when rule assertions fail' {
        Mock Assert-PSRule { throw 'fixture rule assertion failure' }

        { & $assessmentScript } | Should -Throw '*rule assertion failure*'

        Should -Invoke Assert-PSRule -Times 1 -Exactly
        (Get-Content (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'collection-status.json') -Raw | ConvertFrom-Json).Status | Should -Be 'Complete'
        $assessment['continueOnError'] | Should -BeTrue
        $publish['condition'] | Should -Be 'always()'
    }

    It 'rejects an assessment that evaluates no rule results' {
        Mock Assert-PSRule { param($ResultVariable) Set-Variable -Name $ResultVariable -Scope 1 -Value @() }
        { & $assessmentScript } | Should -Throw '*zero rule results*'
    }

    It 'uses fresh exports when the same agent runs again' {
        & $assessmentScript
        '{}' | Set-Content (Join-Path $script:exportPaths[0] 'stale.prj.ado.json')

        & $assessmentScript

        $script:exportPaths.Count | Should -Be 2
        $script:exportPaths[0] | Should -Not -Be $script:exportPaths[1]
        Should -Invoke Assert-PSRule -Times 2 -Exactly
    }
}
