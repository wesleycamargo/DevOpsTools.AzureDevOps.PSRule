BeforeAll {
    $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1'
    $probePath = Join-Path $TestDrive 'Import-ModuleProbe.ps1'
    @'
param($ModulePath, $Scenario)
$ErrorActionPreference = 'Stop'
$accelerators = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
$name = 'AzureDevOpsConnection'
if ($Scenario -eq 'ExistingConnection') {
    # A separate copy models the class exported by a predecessor module.
    $classPath = Join-Path (Split-Path $ModulePath) 'Classes/AzureDevOpsConnection.ps1'
    $legacyClassPath = Join-Path $PSScriptRoot 'LegacyConnection.ps1'
    Copy-Item $classPath $legacyClassPath
    . $legacyClassPath
    $originalType = [AzureDevOpsConnection]
    $accelerators::Add($name, $originalType)
}
if ($Scenario -eq 'ForeignCollision') {
    $accelerators::Add($name, [string])
    try {
        Import-Module $ModulePath
        throw 'Expected a type accelerator conflict.'
    }
    catch {
        if ($_.FullyQualifiedErrorId -notlike 'TypeAcceleratorAlreadyExists*') { throw }
    }
    if ($accelerators::Get[$name] -ne [string]) { throw 'Foreign accelerator was changed.' }
    exit 0
}
$module = Import-Module $ModulePath -PassThru
if (-not (Get-Command Connect-AzDevOps)) { throw 'Module commands were not loaded.' }
if ($Scenario -eq 'ExistingConnection') {
    if ($accelerators::Get[$name] -ne $originalType) { throw 'Existing accelerator was changed.' }
    & $module {
        $script:connection = [AzureDevOpsConnection]::new('example', 'test-only', 'FullAccess')
        if ($script:connection.Organization -ne 'example') { throw 'Connection was not initialized.' }
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
