BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Project export default output directory' -Tag 'Unit' {
    BeforeEach {
        Push-Location $TestDrive
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $script:connection = [pscustomobject]@{ Organization = 'fixture-org' }
        }
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Get-Date { [datetime]'2026-11-07T14:05:00Z' }
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-AzDevOpsProjectExport {
            if ($PassThru) {
                [pscustomobject]@{ ObjectType = 'fixture'; ObjectName = 'fixture-target' }
            }
            else {
                '{"ObjectName":"fixture-target"}' | Set-Content (Join-Path $OutputPath 'fixture.json')
            }
        }
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-AzDevOpsOrganizationExport {}
    }

    AfterEach {
        InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection = $null }
        Pop-Location
        if (Test-Path "$TestDrive/outputs") { Remove-Item "$TestDrive/outputs" -Recurse -Force }
    }

    It 'defaults to reusable outputs with a sibling report' {
        (Get-Command Export-AzDevOpsRuleData).Parameters.OutputPath.Attributes.Mandatory | Should -Not -Contain $true

        $result = @(Export-AzDevOpsRuleData -Project fixture-project)

        $result.Count | Should -Be 0
        $status = Get-Content './outputs/collection-status.json' -Raw | ConvertFrom-Json
        $status.SchemaVersion | Should -Be 1
        $status.Organization | Should -Be 'fixture-org'
        $status.Status | Should -Be 'Complete'
        Test-Path './outputs/targets/collection-status.json' | Should -BeFalse
        (Get-Content './outputs/targets/fixture.json' -Raw | ConvertFrom-Json).ObjectName | Should -Be 'fixture-target'
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-AzDevOpsOrganizationExport -Times 1 -Exactly -ParameterFilter {
            $OutputPath -eq (Join-Path $TestDrive 'outputs/targets')
        }
    }

    It 'preserves an explicit output path and creates its directory' {
        $customPath = Join-Path $TestDrive 'custom/targets'
        Export-AzDevOpsRuleData -Project fixture-project -OutputPath $customPath

        Test-Path (Join-Path $customPath 'fixture.json') | Should -BeTrue
        (Get-Content (Join-Path (Split-Path $customPath -Parent) 'collection-status.json') -Raw | ConvertFrom-Json).Status | Should -Be 'Complete'
        Test-Path './outputs' | Should -BeFalse
    }

    It 'returns PassThru objects without creating an output directory' {
        $targets = @(Export-AzDevOpsRuleData -Project fixture-project -PassThru)

        $targets.Count | Should -Be 1
        $targets[0].ObjectName | Should -Be 'fixture-target'
        Test-Path './outputs' | Should -BeFalse
    }

    It 'cleans current artifacts while preserving retained history' {
        Export-AzDevOpsRuleData -Project fixture-project
        'stale' | Set-Content './outputs/targets/stale.json'
        'old-results' | Set-Content './outputs/rule-results.json'
        New-Item './outputs/2026-11-06-12-00' -ItemType Directory | Out-Null
        'retained' | Set-Content './outputs/2026-11-06-12-00/history.json'

        Export-AzDevOpsRuleData -Project fixture-project -KeepResults:$false

        Test-Path './outputs/targets/stale.json' | Should -BeFalse
        Test-Path './outputs/rule-results.json' | Should -BeFalse
        Test-Path './outputs/targets/fixture.json' | Should -BeTrue
        (Get-Content './outputs/2026-11-06-12-00/history.json' -Raw).Trim() | Should -Be 'retained'
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-AzDevOpsProjectExport -Times 2 -Exactly
    }

    It 'does not create output when disconnected' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection = $null }

        { Export-AzDevOpsRuleData -Project fixture-project } | Should -Throw '*Not connected*'

        Test-Path './outputs' | Should -BeFalse
    }

    It 'gives organization exports the same default run layout' {
        (Get-Command Export-AzDevOpsOrganizationRuleData).Parameters.OutputPath.Attributes.Mandatory | Should -Not -Contain $true
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Get-AzDevOpsProject { [pscustomobject]@{ name = 'fixture-project' } }

        Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111'

        Test-Path './outputs/targets/fixture-project/fixture.json' | Should -BeTrue
        (Get-Content './outputs/collection-status.json' -Raw | ConvertFrom-Json).Status | Should -Be 'Complete'
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-AzDevOpsOrganizationExport -Times 1 -Exactly -ParameterFilter {
            $OutputPath -eq (Join-Path $TestDrive 'outputs/targets')
        }
    }

    It 'uses the explicit report override without writing a second report' {
        $reportPath = Join-Path $TestDrive 'custom-status.json'
        Export-AzDevOpsRuleData -Project fixture-project -CompletenessReportPath $reportPath

        (Get-Content $reportPath -Raw | ConvertFrom-Json).Status | Should -Be 'Complete'
        Test-Path './outputs/targets/fixture.json' | Should -BeTrue
        Test-Path './outputs/collection-status.json' | Should -BeFalse
    }

    It 'rejects reports inside default targets before creating files' {
        { Export-AzDevOpsRuleData -Project fixture-project -CompletenessReportPath './outputs/targets/report.json' } | Should -Throw '*outside*'

        Test-Path './outputs' | Should -BeFalse
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-AzDevOpsProjectExport -Times 0 -Exactly
    }

    It 'supports an explicit report in PassThru mode without creating targets' {
        $reportPath = Join-Path $TestDrive 'passthru-status.json'
        $targets = @(Export-AzDevOpsRuleData -Project fixture-project -PassThru -CompletenessReportPath $reportPath)

        $targets.Count | Should -Be 1
        (Get-Content $reportPath -Raw | ConvertFrom-Json).Status | Should -Be 'Complete'
        Test-Path './outputs' | Should -BeFalse
    }

    It 'retains collected files and writes status before strict mode throws' {
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-AzDevOpsProjectExport {
            '{"ObjectName":"partial-target"}' | Set-Content (Join-Path $OutputPath 'partial.json')
            $Report.Projects += [ordered]@{
                Project = 'fixture-project'
                Collectors = @([ordered]@{
                    Command = 'Export-AzDevOpsProject'
                    Status = 'Failed'
                    ReasonCodes = @('CollectorFailed')
                })
            }
        }

        { Export-AzDevOpsRuleData -Project fixture-project -Strict } | Should -Throw '*collection is incomplete*'

        Test-Path './outputs/targets/partial.json' | Should -BeTrue
        (Get-Content './outputs/collection-status.json' -Raw | ConvertFrom-Json).Status | Should -Be 'Unavailable'
    }

    It 'writes organization status when project discovery is empty' {
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Get-AzDevOpsProject {}
        Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111'

        Test-Path './outputs/targets' | Should -BeTrue
        $status = Get-Content './outputs/collection-status.json' -Raw | ConvertFrom-Json
        $status.Status | Should -Be 'Complete'
        $status.ProjectDiscovery.Status | Should -Be 'Empty'
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-AzDevOpsOrganizationExport -Times 1 -Exactly
    }

    It 'retains dated organization results and rejects same-minute collisions' {
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Get-AzDevOpsProject {}
        (Get-Command Export-AzDevOpsOrganizationRuleData).Parameters.Keys | Should -Contain 'KeepResults'
        Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111' -KeepResults
        $reportPath = './outputs/2026-11-07-14-05/collection-status.json'
        $beforeStatus = Get-Content $reportPath -Raw

        { Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111' -KeepResults } | Should -Throw '*already exists*'

        (Get-Content $reportPath -Raw) | Should -Be $beforeStatus
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Get-AzDevOpsProject -Times 1 -Exactly
    }

    It 'preserves explicit organization target and report locations' {
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Get-AzDevOpsProject {}
        $customPath = Join-Path $TestDrive 'organization-custom/targets'
        $reportPath = Join-Path $TestDrive 'organization-custom-status.json'
        Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111' -OutputPath $customPath -CompletenessReportPath $reportPath

        Test-Path $customPath | Should -BeTrue
        (Get-Content $reportPath -Raw | ConvertFrom-Json).Status | Should -Be 'Complete'
        Test-Path './outputs' | Should -BeFalse
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-AzDevOpsOrganizationExport -Times 1 -Exactly -ParameterFilter { $OutputPath -eq $customPath }
    }

    It 'retains the default organization report on strict discovery failure' {
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Get-AzDevOpsProject { throw 'fixture discovery failure' }

        { Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111' -Strict -ErrorAction SilentlyContinue } | Should -Throw '*collection is incomplete*'

        $status = Get-Content './outputs/collection-status.json' -Raw | ConvertFrom-Json
        $status.ProjectDiscovery.Status | Should -Be 'Failed'
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-AzDevOpsOrganizationExport -Times 1 -Exactly
    }

    It 'keeps dated project runs and does not clean them on a subsequent current run' {
        Export-AzDevOpsRuleData -Project fixture-project -KeepResults
        Test-Path './outputs/2026-11-07-14-05/targets/fixture.json' | Should -BeTrue
        $before = Get-Content './outputs/2026-11-07-14-05/collection-status.json' -Raw
        Export-AzDevOpsRuleData -Project fixture-project
        (Get-Content './outputs/2026-11-07-14-05/collection-status.json' -Raw) | Should -Be $before
        Test-Path './outputs/targets/fixture.json' | Should -BeTrue
    }

    It 'does not clean current results for PassThru or invalid report paths' {
        Export-AzDevOpsRuleData -Project fixture-project
        'preserve' | Set-Content './outputs/targets/stale.json'
        Export-AzDevOpsRuleData -Project fixture-project -PassThru -KeepResults | Out-Null
        { Export-AzDevOpsRuleData -Project fixture-project -CompletenessReportPath './outputs/targets/report.json' } | Should -Throw '*outside*'
        (Get-Content './outputs/targets/stale.json' -Raw).Trim() | Should -Be 'preserve'
    }

    It 'cleans all known current reports but preserves unrelated files' {
        Export-AzDevOpsRuleData -Project fixture-project
        foreach ($name in 'rule-results.json', 'assessment-results.json', 'psrule-results.sarif', 'notes.txt') {
            'old' | Set-Content (Join-Path './outputs' $name)
        }
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Get-AzDevOpsProject {}
        Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111'
        foreach ($name in 'rule-results.json', 'assessment-results.json', 'psrule-results.sarif') {
            Test-Path (Join-Path './outputs' $name) | Should -BeFalse
        }
        Test-Path './outputs/targets/fixture.json' | Should -BeFalse
        Test-Path './outputs/notes.txt' | Should -BeTrue
    }

    It 'rejects linked targets without deleting their contents or the status report' {
        Export-AzDevOpsRuleData -Project fixture-project
        $outside = Join-Path $TestDrive 'outside'
        New-Item $outside -ItemType Directory -Force | Out-Null
        'preserve' | Set-Content (Join-Path $outside 'sentinel.txt')
        New-Item './outputs/targets/link' -ItemType SymbolicLink -Target $outside | Out-Null
        $before = Get-Content './outputs/collection-status.json' -Raw
        { Export-AzDevOpsRuleData -Project fixture-project } | Should -Throw '*linked assessment output*'
        (Get-Content (Join-Path $outside 'sentinel.txt') -Raw).Trim() | Should -Be 'preserve'
        (Get-Content './outputs/collection-status.json' -Raw) | Should -Be $before
    }

    It 'rejects a concurrent retained-run initialization in the same minute' {
        $runDirectory = Join-Path $TestDrive 'retained-concurrent-outputs/2026-11-07-14-05'
        $source = Join-Path $PSScriptRoot '../src/DevOpsTools.AzureDevOps.PSRule/Functions/AssessmentOutput.ps1'
        $reservation = InModuleScope DevOpsTools.AzureDevOps.PSRule -Parameters @{ RunDirectory = $runDirectory } {
            param($RunDirectory)
            Initialize-AzDevOpsAssessmentRunDirectory -RunDirectory $RunDirectory -KeepResults
        }

        try {
            $job = Start-Job -ScriptBlock {
                param($AssessmentOutput, $Path)
                . $AssessmentOutput
                try {
                    $lock = Initialize-AzDevOpsAssessmentRunDirectory -RunDirectory $Path -KeepResults
                    if ($lock) {
                        $lock.ReleaseMutex()
                        $lock.Dispose()
                    }
                    [pscustomobject]@{ Succeeded = $true; Message = $null }
                }
                catch {
                    [pscustomobject]@{ Succeeded = $false; Message = $_.Exception.Message }
                }
            } -ArgumentList $source, $runDirectory
            $result = Receive-Job (Wait-Job $job)

            $result.Succeeded | Should -BeFalse
            $result.Message | Should -Match 'already active'
        }
        finally {
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            if ($reservation) {
                $reservation.ReleaseMutex()
                $reservation.Dispose()
            }
        }
    }

    It 'rejects a concurrent current-run initialization without deleting active evidence' {
        $runDirectory = Join-Path $TestDrive 'concurrent-outputs'
        $source = Join-Path $PSScriptRoot '../src/DevOpsTools.AzureDevOps.PSRule/Functions/AssessmentOutput.ps1'
        $reservation = InModuleScope DevOpsTools.AzureDevOps.PSRule -Parameters @{ RunDirectory = $runDirectory } {
            param($RunDirectory)
            Initialize-AzDevOpsAssessmentRunDirectory -RunDirectory $RunDirectory
        }
        'active-evidence' | Set-Content (Join-Path $runDirectory 'targets/active.ado.json')

        try {
            $job = Start-Job -ScriptBlock {
                param($AssessmentOutput, $Path)
                . $AssessmentOutput
                try {
                    $lock = Initialize-AzDevOpsAssessmentRunDirectory -RunDirectory $Path
                    if ($lock) {
                        $lock.ReleaseMutex()
                        $lock.Dispose()
                    }
                    [pscustomobject]@{ Succeeded = $true; Message = $null }
                }
                catch {
                    [pscustomobject]@{ Succeeded = $false; Message = $_.Exception.Message }
                }
            } -ArgumentList $source, $runDirectory
            $result = Receive-Job (Wait-Job $job)

            $result.Succeeded | Should -BeFalse
            $result.Message | Should -Match 'already active'
            (Get-Content (Join-Path $runDirectory 'targets/active.ado.json') -Raw).Trim() | Should -Be 'active-evidence'
        }
        finally {
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            if ($reservation) {
                $reservation.ReleaseMutex()
                $reservation.Dispose()
            }
        }
    }


    It 'releases an assessment run lock for a separate process' {
        $runDirectory = Join-Path $TestDrive 'released-lock-output'
        $source = Join-Path $PSScriptRoot '../src/DevOpsTools.AzureDevOps.PSRule/Functions/AssessmentOutput.ps1'
        $runLock = InModuleScope DevOpsTools.AzureDevOps.PSRule -Parameters @{ RunDirectory = $runDirectory } {
            param($RunDirectory)
            Initialize-AzDevOpsAssessmentRunDirectory -RunDirectory $RunDirectory
        }

        InModuleScope DevOpsTools.AzureDevOps.PSRule -Parameters @{ RunLock = $runLock } {
            param($RunLock)
            Release-AzDevOpsAssessmentRunLock -RunLock $RunLock
        }

        $job = Start-Job -ScriptBlock {
            param($AssessmentOutput, $Path)
            . $AssessmentOutput
            $lock = Initialize-AzDevOpsAssessmentRunDirectory -RunDirectory $Path
            try { $true }
            finally {
                $lock.ReleaseMutex()
                $lock.Dispose()
            }
        } -ArgumentList $source, $runDirectory
        try {
            (Receive-Job (Wait-Job $job)) | Should -BeTrue
        }
        finally {
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        }
    }

}
