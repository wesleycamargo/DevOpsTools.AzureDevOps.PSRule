BeforeAll {
    $runner = Join-Path $PSScriptRoot '../.vscode/Invoke-Assessment.ps1'
    Import-Module PSRule -RequiredVersion 2.9.0
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
    # Stub Azure authentication boundaries; these Unit tests never sign in.
    function Connect-AzAccount { param($Tenant, [switch]$SkipContextPopulation, [switch]$UseDeviceAuthentication, $Scope) }
    function Get-AzAccessToken { param($TenantId, $ResourceUrl) }
}
Describe 'Interactive VS Code assessment MVP' -Tag 'Unit' {
    BeforeEach {
        $output = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $repository = (Resolve-Path "$PSScriptRoot/..").Path
        Mock Get-Date { [datetime]::new(2026, 11, 7, 14, 5, 42, [DateTimeKind]::Local) }
        Mock Import-Module {}
        Mock Connect-AzAccount {}
        Mock Get-AzAccessToken { [pscustomobject]@{ Token = (ConvertTo-SecureString 'fixture-token' -AsPlainText -Force) } }
        Mock Connect-AzDevOps {}
        Mock Disconnect-AzDevOps {}
        Mock Export-AzDevOpsRuleData {
            param($Project, $OutputPath, $CompletenessReportPath, [switch]$Strict)
            '{"Status":"Complete"}' | Set-Content -LiteralPath $CompletenessReportPath
            '{}' | Set-Content -LiteralPath (Join-Path $OutputPath 'fixture.ado.json')
            'steps: []' | Set-Content -LiteralPath (Join-Path $OutputPath 'fixture.yaml')
        }
        Mock Invoke-PSRule { [pscustomobject]@{ RuleName = 'Fixture.Rule'; Outcome = 'Fail' } }
    }
    It 'uses device authentication, strict collection and explicit JSON files, and retains findings' {
        & $runner -TenantId tenant -Organization org -Project project -RepositoryRoot $repository -OutputRoot $output
        Should -Invoke Connect-AzAccount -Times 1 -Exactly -ParameterFilter { $Tenant -eq 'tenant' -and $SkipContextPopulation -and $UseDeviceAuthentication -and $Scope -eq 'Process' }
        Should -Invoke Get-AzAccessToken -Times 1 -Exactly -ParameterFilter { $ResourceUrl -eq '499b84ac-1321-427f-aa17-267ca6975798' }
        Should -Invoke Connect-AzDevOps -Times 1 -Exactly -ParameterFilter { $Organization -eq 'org' -and $AccessToken -eq 'fixture-token' }
        Should -Invoke Export-AzDevOpsRuleData -Times 1 -Exactly -ParameterFilter { $Project -eq 'project' -and $Strict }
        Should -Invoke Invoke-PSRule -Times 1 -Exactly -ParameterFilter { @($InputPath).Count -eq 1 -and $InputPath[0] -like '*.ado.json' -and $Format -eq 'Json' }
        $files = @(Get-ChildItem $output -Recurse -Filter rule-results.json)
        $files.Count | Should -Be 1
        (Get-Content $files[0].FullName -Raw | ConvertFrom-Json)[0].Outcome | Should -Be 'Fail'
        Should -Invoke Disconnect-AzDevOps -Times 1 -Exactly
    }
    It 'reuses the caller output root and removes stale current evidence by default' {
        & $runner -TenantId tenant -Organization org -Project project -RepositoryRoot $repository -OutputRoot $output
        Test-Path (Join-Path $output 'rule-results.json') | Should -BeTrue
        'stale' | Set-Content (Join-Path $output 'targets/stale.ado.json')
        & $runner -TenantId tenant -Organization org -Project project -RepositoryRoot $repository -OutputRoot $output
        Test-Path (Join-Path $output 'targets/stale.ado.json') | Should -BeFalse
        Should -Invoke Invoke-PSRule -Times 2 -Exactly -ParameterFilter { @($InputPath).Count -eq 1 -and $InputPath[0] -eq (Join-Path $output 'targets/fixture.ado.json') }
    }
    It 'retains exact timestamp output on request and rejects a retained collision' {
        & $runner -TenantId tenant -Organization org -Project project -RepositoryRoot $repository -OutputRoot $output -KeepResults
        $retained = Join-Path $output '2026-11-07-14-05'
        Test-Path (Join-Path $retained 'rule-results.json') | Should -BeTrue
        { & $runner -TenantId tenant -Organization org -Project project -RepositoryRoot $repository -OutputRoot $output -KeepResults } | Should -Throw '*already exists*'
        Should -Invoke Export-AzDevOpsRuleData -Times 1 -Exactly -ParameterFilter { $OutputPath -eq (Join-Path $retained 'targets') -and $CompletenessReportPath -eq (Join-Path $retained 'collection-status.json') -and $Strict }
    }

    It 'defaults to outputs under the caller repository root without retention' {
        $moduleDirectory = Join-Path $TestDrive 'repository/src/DevOpsTools.AzureDevOps.PSRule'
        New-Item (Join-Path $moduleDirectory 'Functions') -ItemType Directory -Force | Out-Null
        Copy-Item (Join-Path $repository 'src/DevOpsTools.AzureDevOps.PSRule/Functions/AssessmentOutput.ps1') (Join-Path $moduleDirectory 'Functions/AssessmentOutput.ps1')
        '{}' | Set-Content (Join-Path $moduleDirectory 'DevOpsTools.AzureDevOps.PSRule.psd1')
        $repositoryRoot = Join-Path $TestDrive 'repository'
        & $runner -TenantId tenant -Organization org -Project project -RepositoryRoot $repositoryRoot
        Test-Path (Join-Path $repositoryRoot 'outputs/rule-results.json') | Should -BeTrue
        Should -Invoke Export-AzDevOpsRuleData -Times 1 -Exactly -ParameterFilter { $OutputPath -eq (Join-Path $repositoryRoot 'outputs/targets') -and $CompletenessReportPath -eq (Join-Path $repositoryRoot 'outputs/collection-status.json') }
    }


    It 'scopes the assessment output lock in a finally block' {
        $contents = Get-Content -LiteralPath $runner -Raw

        $contents | Should -Match '(?s)\$runLock\s*=\s*Initialize-AzDevOpsAssessmentRunDirectory.*finally\s*\{.*Release-AzDevOpsAssessmentRunLock\s+-RunLock\s+\$runLock'
    }

}
