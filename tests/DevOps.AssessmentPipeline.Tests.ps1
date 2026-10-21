BeforeAll {
    Import-Module PSRule
    Import-Module "$PSScriptRoot/../src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psd1" -Force
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
        Mock Connect-AzDevOps {}
        Mock Export-AzDevOpsOrganizationRuleData {
            param ($OutputPath, $CompletenessReportPath, [switch]$Strict)
            $script:exportPaths += $OutputPath
            @{ Status = $script:collectionStatus } | ConvertTo-Json | Set-Content $CompletenessReportPath
            if ($script:collectionStatus -ne 'Complete' -and $Strict) {
                throw 'Assessment collection is incomplete.'
            }
            '{}' | Set-Content (Join-Path $OutputPath 'fixture.prj.ado.json')
        }
        Mock Export-AzDevOpsAssessmentRun {
            param ($OutputPath)
            @{ RuleSetVersion = '2026.10.21.1'; SeverityPolicyVersion = '1.0.0'; Projects = @() } | ConvertTo-Json | Set-Content $OutputPath
        }
        Mock Assert-PSRule {
            param ($InputPath, $OutputPath)
            @((Get-ChildItem $InputPath).Name) | Should -Be @('fixture.prj.ado.json')
            '{}' | Set-Content $OutputPath
        }
    }

    AfterEach {
        foreach ($name in $savedEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name])
        }
    }

    It 'assesses complete exports and publishes only separate reports' {
        & $assessmentScript

        Should -Invoke Assert-PSRule -Times 1 -Exactly -ParameterFilter { $InputPath.EndsWith([string][IO.Path]::DirectorySeparatorChar) -and $Outcome -eq 'All' }
        Should -Invoke Export-AzDevOpsAssessmentRun -Times 1 -Exactly -ParameterFilter { $SourceRevision -eq 'synthetic-commit' -and $Organization -eq 'fixture-org' }
        (Get-Content (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'collection-status.json') -Raw | ConvertFrom-Json).Status | Should -Be 'Complete'
        Test-Path (Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'psrule-results.sarif') | Should -BeTrue
        $script:exportPaths[0].StartsWith($env:AGENT_TEMPDIRECTORY) | Should -BeTrue
        $publish['inputs']['PathtoPublish'] | Should -Be '$(Build.ArtifactStagingDirectory)'
        @((Get-ChildItem $env:BUILD_ARTIFACTSTAGINGDIRECTORY).Name) | Should -Be @('assessment-results.json', 'collection-status.json', 'psrule-results.sarif')
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

    It 'uses fresh exports when the same agent runs again' {
        & $assessmentScript
        '{}' | Set-Content (Join-Path $script:exportPaths[0] 'stale.prj.ado.json')

        & $assessmentScript

        $script:exportPaths.Count | Should -Be 2
        $script:exportPaths[0] | Should -Not -Be $script:exportPaths[1]
        Should -Invoke Assert-PSRule -Times 2 -Exactly
    }
}
