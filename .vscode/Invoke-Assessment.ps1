#Requires -Version 7.2
<#
.SYNOPSIS
Prompt for tenant, organization and project, then run a manual assessment.
.DESCRIPTION
Requires Az.Accounts, PSRule 2.9.0 and this repository. No PAT, Azure CLI or
Azure subscription is required. Uses device authentication and JSON evidence.
#>
[CmdletBinding()]
param (
    [string]$TenantId,
    [string]$Organization,
    [string]$Project,
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputRoot,
    [switch]$KeepResults
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($TenantId)) { $TenantId = Read-Host 'Microsoft Entra tenant ID (GUID)' }
if ([string]::IsNullOrWhiteSpace($Organization)) { $Organization = Read-Host 'Azure DevOps organization name (not URL)' }
if ([string]::IsNullOrWhiteSpace($Project)) { $Project = Read-Host 'Azure DevOps project name' }
foreach ($value in @($TenantId, $Organization, $Project)) {
    if ([string]::IsNullOrWhiteSpace($value)) { throw 'Tenant, organization and project are required.' }
}
if ($Organization -match '[/\\:]') { throw 'Enter the organization name, not a URL.' }

$modulePath = Join-Path $RepositoryRoot 'src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1'
if (-not (Test-Path -LiteralPath $modulePath)) { throw 'Place this script in the repository .vscode directory, or specify -RepositoryRoot.' }
try { Import-Module Az.Accounts -ErrorAction Stop }
catch { throw 'Install the dependency first: Install-Module Az.Accounts -Scope CurrentUser' }
try { Import-Module PSRule -RequiredVersion 2.9.0 -ErrorAction Stop }
catch { throw 'Install the dependency first: Install-Module PSRule -RequiredVersion 2.9.0 -Scope CurrentUser' }
Import-Module $modulePath -Force

. (Join-Path $RepositoryRoot 'src/DevOpsTools.AzureDevOps.PSRule/Functions/AssessmentOutput.ps1')
if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $OutputRoot = Join-Path $RepositoryRoot 'outputs' }
$connected = $false
$accessToken = $null
$azToken = $null
$runLock = $null
try {
    Write-Host 'Sign in using the device-code instructions below. Do not share the code.'
    Connect-AzAccount -Tenant $TenantId -SkipContextPopulation -UseDeviceAuthentication -Scope Process | Out-Null
    $azToken = Get-AzAccessToken -TenantId $TenantId -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798'
    $accessToken = [System.Net.NetworkCredential]::new('', $azToken.Token).Password
    if ([string]::IsNullOrWhiteSpace($accessToken)) { throw 'No Azure DevOps access token was returned.' }
    Connect-AzDevOps -Organization $Organization -AccessToken $accessToken
    $connected = $true

    $paths = Get-AzDevOpsAssessmentRunPaths -OutputRoot $OutputRoot -KeepResults:$KeepResults
    $runDirectory = $paths.RunDirectory
    $targets = $paths.OutputPath
    $coverage = $paths.CompletenessReportPath
    $runLock = Initialize-AzDevOpsAssessmentRunDirectory -RunDirectory $runDirectory -KeepResults:$KeepResults
    Write-Host "Assessment output: $runDirectory"
    Export-AzDevOpsRuleData -Project $Project -OutputPath $targets -CompletenessReportPath $coverage -Strict
    $report = Get-Content -LiteralPath $coverage -Raw | ConvertFrom-Json
    if ($report.Status -ne 'Complete') { throw "Collection is incomplete. Inspect $coverage" }

    $inputFiles = @(Get-ChildItem -LiteralPath $targets -File -Recurse -Filter '*.json' | Select-Object -ExpandProperty FullName)
    if ($inputFiles.Count -eq 0) { throw 'No JSON evidence files were exported.' }
    $results = @(Invoke-PSRule -InputPath $inputFiles -Format Json -Module DevOpsTools.AzureDevOps.PSRule -Baseline Baseline.Default)
    if ($results.Count -eq 0) { throw 'Zero rule results. No assessment can be claimed.' }
    $resultsPath = Join-Path $runDirectory 'rule-results.json'
    ConvertTo-Json -InputObject $results -Depth 30 | Set-Content -LiteralPath $resultsPath -Encoding utf8
    $results | Group-Object Outcome | Select-Object Name, Count | Format-Table -AutoSize
    Write-Host "Results: $resultsPath"
    Write-Host "Collection status: $coverage"
    if (@($results | Where-Object Outcome -EQ 'Error').Count) { throw 'Rule execution errors occurred. Inspect rule-results.json.' }
    if (@($results | Where-Object { $_.Outcome -in 'Pass', 'Fail' }).Count -eq 0) { throw 'No rules passed or failed; this was not an effective assessment.' }
    Write-Host 'Finished. Fail outcomes are security findings, not script errors.'
    Write-Host 'This MVP evaluates JSON evidence only, not separate pipeline YAML files.'
}
finally {
    Release-AzDevOpsAssessmentRunLock -RunLock $runLock
    $accessToken = $null
    $azToken = $null
    if ($connected) { Disconnect-AzDevOps }
}
