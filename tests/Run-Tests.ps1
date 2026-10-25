[CmdletBinding()]
param(
    [ValidateSet('Unit', 'Integration', 'Authentication')]
    [string]$TestType = 'Unit',

    [string]$ResultPath = (Join-Path $PSScriptRoot '../testresults.xml'),

    # Integration and Authentication defaults, used only when the matching ADO_* variable is not already set.
    [string]$Organization = 'ai-experiments',

    [string]$Project = 'PSRule.Rules.AzureDevOps.Tests',

    [switch]$Coverage
)

$ErrorActionPreference = 'Stop'

if ($TestType -in 'Integration', 'Authentication') {
    # Variables that are already set (for example PATs in CI) are kept.
    if (-not $env:ADO_ORGANIZATION) { $env:ADO_ORGANIZATION = $Organization }
    if (-not $env:ADO_PROJECT) { $env:ADO_PROJECT = $Project }
    if (-not $env:ADO_EXPORT_DIR) {
        $env:ADO_EXPORT_DIR = (New-Item -Path (Join-Path $PSScriptRoot 'outExport') -ItemType Directory -Force).FullName
    }

    # An Azure CLI access token works for both PAT and bearer connections.
    $tokenVariables = 'ADO_PAT', 'ADO_PAT_READONLY', 'ADO_PAT_FINEGRAINED', 'ADO_ACCESS_TOKEN'
    $missing = @($tokenVariables | Where-Object { -not [Environment]::GetEnvironmentVariable($_) })
    if ($missing) {
        $token = $null
        if (Get-Command az -ErrorAction SilentlyContinue) {
            $token = az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv 2>$null
        }
        if (-not $token) {
            throw "$TestType tests need $($missing -join ', '). Set them, or sign in with 'az login' so they can be taken from the Azure CLI."
        }
        foreach ($name in $missing) { [Environment]::SetEnvironmentVariable($name, $token) }
    }

    if ($TestType -eq 'Authentication') {
        $servicePrincipal = @('ADO_CLIENT_ID', 'ADO_CLIENT_SECRET', 'ADO_TENANT_ID' | Where-Object { -not [Environment]::GetEnvironmentVariable($_) })
        if ($servicePrincipal) {
            Write-Warning "Service principal tests will fail without $($servicePrincipal -join ', ')."
        }
    }

    Write-Host "$TestType target: $env:ADO_ORGANIZATION/$env:ADO_PROJECT"
}

$pester = Get-Module -ListAvailable Pester | Where-Object {
    $_.Version -eq [version]'5.7.1'
} | Sort-Object Version -Descending | Select-Object -First 1

if ($null -eq $pester) {
    throw 'Pester 5.7.x is required. Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser'
}

Import-Module $pester.Path -Force
Import-Module PSRule -RequiredVersion (Import-PowerShellDataFile "$PSScriptRoot/requirements.psd1").PSRule -Force

$configuration = New-PesterConfiguration
$configuration.Run.Path = $PSScriptRoot
$configuration.Filter.Tag = $TestType
$configuration.Run.Exit = $true
$configuration.Output.Verbosity = 'Detailed'
$configuration.TestResult.Enabled = $true
$configuration.TestResult.OutputFormat = 'NUnitXml'
$configuration.TestResult.OutputPath = $ResultPath
if ($Coverage) {
    $configuration.CodeCoverage.Enabled = $true
    $configuration.CodeCoverage.Path = @(
        (Join-Path $PSScriptRoot '../src/PSRule.Rules.AzureDevOps/Functions'),
        (Join-Path $PSScriptRoot '../src/PSRule.Rules.AzureDevOps/Classes'),
        (Join-Path $PSScriptRoot '../src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psm1')
    )
    $configuration.CodeCoverage.OutputFormat = 'JaCoCo'
    $configuration.CodeCoverage.OutputPath = Join-Path (Split-Path $ResultPath -Parent) 'coverage.xml'
}

Invoke-Pester -Configuration $configuration
