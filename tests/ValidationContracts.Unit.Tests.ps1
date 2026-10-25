BeforeAll {
    Import-Module PSRule -RequiredVersion 2.9.0
    Add-Type -Path (Join-Path (Get-Module PSRule).ModuleBase 'YamlDotNet.dll')
    $deserializer = [YamlDotNet.Serialization.DeserializerBuilder]::new().Build()
    $workflow = $deserializer.Deserialize([IO.StringReader]::new((Get-Content "$PSScriptRoot/../.github/workflows/module-ci.yml" -Raw)))
    $publishing = $deserializer.Deserialize([IO.StringReader]::new((Get-Content "$PSScriptRoot/../.github/workflows/publish-on-release.yml" -Raw)))
}

Describe 'Validation and publishing contracts' -Tag Unit {
    It 'runs the shared pinned runner and retains diagnostics after failures' {
        $steps = $workflow['jobs']['run-pester']['steps']
        ($steps | Where-Object { $_['name'] -eq 'Run Pester Tests' })['run'] | Should -Match 'Run-Tests.ps1 -TestType Unit -Coverage'
        ($steps | Where-Object { $_['name'] -eq 'Install PSRule and Pester' })['run'] | Should -Match 'requirements.psd1'
        foreach ($name in 'Upload Test Results', 'Upload Code Coverage') {
            ($steps | Where-Object { $_['name'] -eq $name })['if'] | Should -Be 'always()'
        }
        foreach ($eventName in 'pull_request', 'push') {
            $paths = $workflow['on'][$eventName]['paths']
            $paths | Should -Contain 'src/DevOpsTools.AzureDevOps.Assessment/**'
            $paths | Should -Contain 'pipelines/**'
            $paths | Should -Contain 'tests/**'
            $paths | Should -Contain '.github/workflows/**'
        }
    }

    It 'fails the actual local runner on a deliberate offline assertion failure' {
        $runnerPath = Join-Path $TestDrive 'runner'
        New-Item $runnerPath -ItemType Directory | Out-Null
        Copy-Item "$PSScriptRoot/Run-Tests.ps1", "$PSScriptRoot/requirements.psd1" $runnerPath
        "Describe 'Intentional runner probe' -Tag Unit { It 'fails' { 1 | Should -Be 2 } }" | Set-Content "$runnerPath/Failure.Tests.ps1"
        $resultPath = Join-Path $runnerPath 'results.xml'
        $null = & (Get-Process -Id $PID).Path -NoProfile -File "$runnerPath/Run-Tests.ps1" -ResultPath $resultPath
        $LASTEXITCODE | Should -Be 1
        Test-Path $resultPath | Should -BeTrue
    }

    It 'validates an explicit manual tag before optional publishing' {
        $publishing['on']['workflow_dispatch']['inputs'].ContainsKey('tag') | Should -BeTrue
        $publishing['on']['workflow_dispatch']['inputs']['publish']['default'] | Should -Be 'false'
        $steps = $publishing['jobs']['publish']['steps']
        ($steps | Where-Object { $_['name'] -eq 'Validate manifest version' })['run'] | Should -Match 'Tag and module manifest versions differ'
        ($steps | Where-Object { $_['name'] -eq 'Run offline tests' })['run'] | Should -Match 'Run-Tests.ps1'
        ($steps | Where-Object { $_['name'] -eq 'Build module package' })['run'] | Should -Match 'Build-Module.ps1'
        (Get-Content "$PSScriptRoot/../.github/workflows/publish-on-release.yml" -Raw) | Should -Not -Match 'github.event.release'
    }
}
