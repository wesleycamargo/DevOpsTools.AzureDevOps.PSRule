BeforeAll {
    $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1'
    $probePath = Join-Path $TestDrive 'Import-ModuleProbe.ps1'
    @'
param($ModulePath, $Scenario)
$ErrorActionPreference = 'Stop'
$accelerators = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
$name = 'AzureDevOpsConnection'
if ($Scenario -eq 'ExistingConnection') {
    # An incompatible predecessor class must never be used by Connect-AzDevOps.
    $legacyClassPath = Join-Path $PSScriptRoot 'LegacyConnection.ps1'
    'class AzureDevOpsConnection {}' | Set-Content $legacyClassPath
    . $legacyClassPath
    $originalType = [AzureDevOpsConnection]
    $accelerators::Add($name, $originalType)
}
if ($Scenario -eq 'ForeignCollision') {
    $originalType = [string]
    $accelerators::Add($name, $originalType)
}
$module = Import-Module $ModulePath -PassThru
if (-not (Get-Command Connect-AzDevOps)) { throw 'Module commands were not loaded.' }
if ($Scenario -notin 'ExistingConnection', 'ForeignCollision') {
    if ($accelerators::Get[$name].FullName -ne 'DevOpsToolsAzureDevOpsConnection') {
        throw 'Compatibility shortcut does not point to the module connection class.'
    }
}
if ($Scenario -in 'ExistingConnection', 'ForeignCollision') {
    if ($accelerators::Get[$name] -ne $originalType) { throw 'Existing accelerator was changed.' }
}
& $module {
    # Stub only the remote verification; exercise the exported connection command.
    function Invoke-RestMethod { [pscustomobject]@{ value = @() } }
    Connect-AzDevOps -Organization example -OrganizationId '11111111-1111-1111-1111-111111111111' -PAT 'test-only'
    if ($script:connection.GetType().FullName -ne 'DevOpsToolsAzureDevOpsConnection') {
        throw 'Connect-AzDevOps did not create the module-owned connection type.'
    }
    if ($script:connection.AuthType -ne 'PAT' -or $script:connection.Organization -ne 'example') {
        throw 'Connection was not initialized.'
    }
}
if ($Scenario -eq 'Reload') {
    Import-Module $ModulePath -Force
    if (-not $accelerators::Get.ContainsKey($name)) { throw 'Reload lost the accelerator.' }
}
if ($Scenario -eq 'Replacement') {
    $accelerators::Remove($name) | Out-Null
    $accelerators::Add($name, [string])
}
Remove-Module $module.Name -Force
switch ($Scenario) {
    ExistingConnection { if ($accelerators::Get[$name] -ne $originalType) { throw 'Removed another owner''s accelerator.' } }
    ForeignCollision { if ($accelerators::Get[$name] -ne $originalType) { throw 'Removed another owner''s accelerator.' } }
    Replacement { if ($accelerators::Get[$name] -ne [string]) { throw 'Removed a replacement accelerator.' } }
    default { if ($accelerators::Get.ContainsKey($name)) { throw 'Module accelerator was not cleaned up.' } }
}
'@ | Set-Content $probePath
}

Describe 'Module type accelerator lifecycle' -Tag Unit {
    It 'handles <Scenario> in an isolated PowerShell session' -ForEach @(
        @{ Scenario = 'FreshImport' }
        @{ Scenario = 'Reload' }
        @{ Scenario = 'ExistingConnection' }
        @{ Scenario = 'ForeignCollision' }
        @{ Scenario = 'Replacement' }
    ) {
        & (Get-Process -Id $PID).Path -NoProfile -File $probePath $modulePath $Scenario
        $LASTEXITCODE | Should -Be 0
    }
}
