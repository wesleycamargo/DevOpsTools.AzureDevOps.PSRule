[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('5.1', '7.0')]
    [string]$ExpectedVersion,

    [Parameter(Mandatory)]
    [string]$ScratchRoot
)

$ErrorActionPreference = 'Stop'
$actualVersion = '{0}.{1}' -f $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor
if ($actualVersion -ne $ExpectedVersion) {
    throw "Expected PowerShell $ExpectedVersion but running $actualVersion."
}
$source = Join-Path $PSScriptRoot '../src/DevOpsTools.AzureDevOps.PSRule/Functions/AssessmentOutput.ps1'
. $source
$path = Join-Path $ScratchRoot ('assessment-output-' + [guid]::NewGuid().ToString('N'))
$lock = $null
$opened = $null
$job = $null
try {
    $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = $algorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes($resolved))
        $name = 'AzDevOpsAssessmentRun-' + [BitConverter]::ToString($hash).Replace('-', '')
    }
    finally { $algorithm.Dispose() }

    $lock = Initialize-AzDevOpsAssessmentRunDirectory -RunDirectory $path
    if ($lock -isnot [Threading.Mutex] -or -not (Test-Path -LiteralPath (Join-Path $path 'targets'))) {
        throw 'Initialization did not return a mutex and create targets.'
    }
    $opened = [Threading.Mutex]::OpenExisting($name)
    $opened.Dispose()
    $opened = $null
    $sentinel = Join-Path $path 'targets/active.txt'
    Set-Content -LiteralPath $sentinel -Value 'active-evidence'

    $job = Start-Job -ScriptBlock {
        param($Source, $Path)
        $ErrorActionPreference = 'Stop'
        . $Source
        $secondLock = $null
        try {
            $secondLock = Initialize-AzDevOpsAssessmentRunDirectory -RunDirectory $Path
            'unexpected-acquisition'
        }
        catch {
            if ($_.Exception.Message -like '*already active*') { 'blocked' }
            else { throw }
        }
        finally { Release-AzDevOpsAssessmentRunLock -RunLock $secondLock }
    } -ArgumentList $source, $path
    if ($null -eq (Wait-Job -Job $job -Timeout 30)) { throw 'Contention check timed out.' }
    $result = @(Receive-Job -Job $job -ErrorAction Stop)
    if ($job.State -ne 'Completed' -or $result.Count -ne 1 -or $result[0] -ne 'blocked') {
        throw 'A second process was not rejected by the held lock.'
    }
    if ((Get-Content -LiteralPath $sentinel -Raw).Trim() -ne 'active-evidence') {
        throw 'Contending initialization altered active evidence.'
    }
    Remove-Job -Job $job -Force
    $job = $null
    Release-AzDevOpsAssessmentRunLock -RunLock $lock
    $lock = $null

    $job = Start-Job -ScriptBlock {
        param($Source, $Path)
        $ErrorActionPreference = 'Stop'
        . $Source
        $nextLock = Initialize-AzDevOpsAssessmentRunDirectory -RunDirectory $Path
        try { 'reacquired' }
        finally { Release-AzDevOpsAssessmentRunLock -RunLock $nextLock }
    } -ArgumentList $source, $path
    if ($null -eq (Wait-Job -Job $job -Timeout 30)) { throw 'Reacquisition check timed out.' }
    $result = @(Receive-Job -Job $job -ErrorAction Stop)
    if ($job.State -ne 'Completed' -or $result.Count -ne 1 -or $result[0] -ne 'reacquired') {
        throw 'A second process could not acquire the released lock.'
    }
    Write-Output "PASS PowerShell $actualVersion output initialization, mutex identity, contention, and release"
}
finally {
    if ($null -ne $job) { Remove-Job -Job $job -Force -ErrorAction SilentlyContinue }
    if ($null -ne $opened) { $opened.Dispose() }
    Release-AzDevOpsAssessmentRunLock -RunLock $lock
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force }
}
