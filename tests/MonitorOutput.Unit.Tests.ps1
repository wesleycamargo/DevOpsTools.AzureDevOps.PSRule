BeforeAll {
    Import-Module PSRule
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
    Add-Type -Path (Join-Path (Get-Module PSRule).ModuleBase 'YamlDotNet.dll')
    $deserializer = [YamlDotNet.Serialization.DeserializerBuilder]::new().Build()
    $workflow = $deserializer.Deserialize([System.IO.StringReader]::new(
        (Get-Content "$PSScriptRoot/../.github/workflows/psrule-monitor.yml" -Raw)))
    $step = @($workflow['jobs']['run-psrule-monitor']['steps'] | Where-Object { $_['name'] -eq 'Run PSRule' })[0]
    $scriptText = $step['run'].Replace('${{ secrets.ADO_ORGANIZATION }}', 'fixture-org').Replace('${{ secrets.ADO_ORGANIZATION_ID }}', '11111111-1111-1111-1111-111111111111').Replace('${{ secrets.ADO_PAT }}', 'fixture-pat')
    $monitorScript = [scriptblock]::Create($scriptText)
    # PSRule.Monitor is not installed or called by these offline workflow tests.
    function Send-PSRuleMonitorRecord {
        param ([Parameter(ValueFromPipeline)]$InputObject, $WorkspaceId, $SharedKey, $LogName)
        process { }
    }
}

Describe 'PSRule monitor output' -Tag 'Unit' {
    BeforeEach {
        $savedKeepResults = $env:KEEP_RESULTS
        $env:KEEP_RESULTS = 'false'
        $savedTimeZone = $env:TZ
        $env:TZ = 'Etc/GMT-2'
        [TimeZoneInfo]::ClearCachedData()
        $workingDirectory = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item $workingDirectory -ItemType Directory | Out-Null
        New-Item -ItemType SymbolicLink -Path (Join-Path $workingDirectory 'src') -Target (Join-Path $PSScriptRoot '../src') | Out-Null
        Push-Location $workingDirectory
        $expectedRun = Join-Path $workingDirectory 'outputs'
        $expectedTargets = Join-Path $expectedRun 'targets'
        $expectedStatus = Join-Path $expectedRun 'collection-status.json'
        Mock Get-Date { [datetime]::new(2026, 11, 7, 14, 5, 42, [DateTimeKind]::Local) }
        Mock Import-Module {}
        Mock Connect-AzDevOps {
            param ($Organization, $OrganizationId, $PAT)
        }
        Mock Invoke-RestMethod { throw 'Unexpected network call in offline test.' }
        Mock Export-AzDevOpsOrganizationRuleData {
            param ($Organization, $OrganizationId, $OutputPath, $CompletenessReportPath)
            '{"ObjectName":"fixture-target"}' | Set-Content (Join-Path $OutputPath 'fixture.ado.json')
            if ($CompletenessReportPath) {
                '{"Status":"Complete"}' | Set-Content $CompletenessReportPath
            }
        }
        Mock Invoke-PSRule { [pscustomobject]@{ Outcome = 'Pass' } }
        Mock Send-PSRuleMonitorRecord {}
    }

    AfterEach {
        Pop-Location
        $env:KEEP_RESULTS = $savedKeepResults
        $env:TZ = $savedTimeZone
        [TimeZoneInfo]::ClearCachedData()
    }

    It 'evaluates only current targets with a sibling collection report' {
        $workflow['on']['workflow_dispatch']['inputs']['KeepResults']['type'] | Should -Be 'boolean'
        $workflow['on']['workflow_dispatch']['inputs']['KeepResults']['default'] | Should -Be 'false'
        $step['env']['KEEP_RESULTS'] | Should -Be '${{ inputs.KeepResults || false }}'
        & $monitorScript

        Test-Path (Join-Path $expectedTargets 'fixture.ado.json') | Should -BeTrue
        (Get-Content $expectedStatus -Raw | ConvertFrom-Json).Status | Should -Be 'Complete'
        Test-Path (Join-Path $expectedTargets 'collection-status.json') | Should -BeFalse
        Should -Invoke Export-AzDevOpsOrganizationRuleData -Times 1 -Exactly -ParameterFilter {
            $Organization -eq 'fixture-org' -and
            $OrganizationId -eq '11111111-1111-1111-1111-111111111111' -and
            $OutputPath -eq $expectedTargets -and
            $CompletenessReportPath -eq $expectedStatus
        }
        Should -Invoke Connect-AzDevOps -Times 1 -Exactly -ParameterFilter {
            $Organization -eq 'fixture-org' -and
            $OrganizationId -eq '11111111-1111-1111-1111-111111111111'
        }
        Should -Invoke Invoke-PSRule -Times 1 -Exactly -ParameterFilter { $InputPath -eq $expectedTargets }
        Should -Invoke Send-PSRuleMonitorRecord -Times 1 -Exactly
        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
    }

    It 'rejects a same-minute repeated retained run without deleting or assessing stale evidence' {
        $env:KEEP_RESULTS = 'true'
        $expectedRun = Join-Path $workingDirectory 'outputs/2026-11-07-14-05'
        $expectedTargets = Join-Path $expectedRun 'targets'
        $expectedStatus = Join-Path $expectedRun 'collection-status.json'
        & $monitorScript
        $stalePath = Join-Path $expectedTargets 'stale.ado.json'
        'stale-evidence' | Set-Content $stalePath
        $statusBefore = Get-Content $expectedStatus -Raw

        { & $monitorScript } | Should -Throw '*already exists*'

        Get-Content $stalePath -Raw | Should -Be "stale-evidence`n"
        Get-Content $expectedStatus -Raw | Should -Be $statusBefore
        Should -Invoke Export-AzDevOpsOrganizationRuleData -Times 1 -Exactly
        Should -Invoke Invoke-PSRule -Times 1 -Exactly
        Should -Invoke Send-PSRuleMonitorRecord -Times 1 -Exactly
    }
    It 'removes stale current targets on repeated default runs' {
        & $monitorScript
        $stale = Join-Path $expectedTargets 'stale.ado.json'
        '{}' | Set-Content $stale
        & $monitorScript
        Test-Path $stale | Should -BeFalse
        Should -Invoke Invoke-PSRule -Times 2 -Exactly -ParameterFilter { $InputPath -eq $expectedTargets }
    }


    It 'scopes the assessment output lock in a finally block' {
        $step['run'] | Should -Match '(?s)\$runLock\s*=\s*Initialize-AzDevOpsAssessmentRunDirectory.*finally\s*\{.*Release-AzDevOpsAssessmentRunLock\s+-RunLock\s+\$runLock'
    }

}
