# Shared by the aggregate exporters and repository assessment runners.
function Get-AzDevOpsAssessmentRunPaths {
    param ([Parameter(Mandatory)][string]$OutputRoot, [switch]$KeepResults)

    $runDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputRoot)
    if ($KeepResults) { $runDirectory = Join-Path $runDirectory ((Get-Date).ToString('yyyy-MM-dd-HH-mm')) }
    [pscustomobject]@{
        RunDirectory = $runDirectory
        OutputPath = Join-Path $runDirectory 'targets'
        CompletenessReportPath = Join-Path $runDirectory 'collection-status.json'
    }
}

function Initialize-AzDevOpsAssessmentRunDirectory {
    param ([Parameter(Mandatory)][string]$RunDirectory, [switch]$KeepResults)

    $RunDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RunDirectory)
    # Hold this process-wide reservation until the caller finishes writing the run.
    $hash = [Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($RunDirectory))
    $mutex = [Threading.Mutex]::new($false, "AzDevOpsAssessmentRun-$([Convert]::ToHexString($hash))")
    $lockAcquired = $false
    try {
        try {
            $lockAcquired = $mutex.WaitOne(0)
        }
        catch [Threading.AbandonedMutexException] {
            $lockAcquired = $true
        }
        if (-not $lockAcquired) {
            throw "Assessment output directory is already active: $RunDirectory. Retry after the current run completes."
        }

        if (Test-Path -LiteralPath $RunDirectory) {
            $directory = Get-Item -LiteralPath $RunDirectory -Force -ErrorAction Stop
            if (-not $directory.PSIsContainer -or ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw "Assessment output must be a normal directory: $RunDirectory"
            }
            if ($KeepResults) { throw "Retained output directory already exists: $RunDirectory. Retry in the next minute." }
        }

        # Delete only current-run artifacts, never retained history or unrelated files.
        $existing = @(
            foreach ($name in 'targets', 'collection-status.json', 'rule-results.json', 'psrule-results.sarif', 'assessment-results.json') {
                $path = Join-Path $RunDirectory $name
                if (Test-Path -LiteralPath $path) {
                    $item = Get-Item -LiteralPath $path -Force -ErrorAction Stop
                    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Refusing to clean linked assessment output: $path" }
                    if ($item.PSIsContainer) {
                        $links = @(Get-ChildItem -LiteralPath $path -Recurse -Force -ErrorAction Stop |
                            Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
                        if ($links.Count) { throw "Refusing to clean linked assessment output: $path" }
                    }
                    $path
                }
            }
        )
        foreach ($path in $existing) { Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop }
        New-Item -Path (Join-Path $RunDirectory 'targets') -ItemType Directory -Force -ErrorAction Stop | Out-Null
        return $mutex
    }
    catch {
        if ($lockAcquired) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
        throw
    }
}

function Release-AzDevOpsAssessmentRunLock {
    param ([System.Threading.Mutex]$RunLock)

    if ($null -eq $RunLock) { return }
    try {
        $RunLock.ReleaseMutex()
    }
    finally {
        $RunLock.Dispose()
    }
}
