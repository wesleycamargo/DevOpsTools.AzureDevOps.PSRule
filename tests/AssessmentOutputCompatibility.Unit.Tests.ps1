BeforeAll {
    $source = Join-Path $PSScriptRoot '../src/DevOpsTools.AzureDevOps.PSRule/Functions/AssessmentOutput.ps1'
    . $source
}

Describe 'Assessment output hashing compatibility' -Tag Unit {
    It 'avoids static hashing and hex APIs absent from the minimum runtimes' {
        $contents = Get-Content -LiteralPath $source -Raw
        $contents | Should -Not -Match '\]::HashData\s*\('
        $contents | Should -Not -Match '\]::ToHexString\s*\('
    }

    It 'creates the legacy uppercase mutex name without importing the module' {
        $path = Join-Path $TestDrive 'standalone-output'
        $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
        $algorithm = [Security.Cryptography.SHA256]::Create()
        try {
            $hash = $algorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes($resolved))
            $expectedName = 'AzDevOpsAssessmentRun-' + [BitConverter]::ToString($hash).Replace('-', '')
        }
        finally { $algorithm.Dispose() }

        $runLock = $null
        $opened = $null
        try {
            $runLock = Initialize-AzDevOpsAssessmentRunDirectory -RunDirectory $path
            $runLock | Should -BeOfType ([Threading.Mutex])
            Test-Path -LiteralPath (Join-Path $path 'targets') | Should -BeTrue
            $opened = [Threading.Mutex]::OpenExisting($expectedName)
            $opened | Should -BeOfType ([Threading.Mutex])
        }
        finally {
            if ($null -ne $opened) { $opened.Dispose() }
            Release-AzDevOpsAssessmentRunLock -RunLock $runLock
        }
    }
}
