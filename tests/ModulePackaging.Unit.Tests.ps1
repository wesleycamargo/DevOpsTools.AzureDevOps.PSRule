BeforeAll {
    $repositoryPath = Split-Path $PSScriptRoot -Parent
    $moduleName = 'DevOpsTools.AzureDevOps.PSRule'
    $expectedGuid = [guid]'f77fbd3d-03be-4e42-98f3-4c185cc93bba'
}

Describe 'Assessment module distribution' -Tag Unit {
    It 'includes the GPLv3 license in the source published to PowerShell Gallery' {
        $modulePath = Join-Path $repositoryPath "src/$moduleName"
        (Get-FileHash "$modulePath/LICENSE").Hash | Should -Be (Get-FileHash "$repositoryPath/LICENSE").Hash
        $manifest = Import-PowerShellDataFile "$modulePath/$moduleName.psd1"
        $manifest.PrivateData.PSData.LicenseUri | Should -Be 'https://www.gnu.org/licenses/gpl-3.0.html'
    }

    It 'packages the renamed module for an isolated version-qualified import' {
        $outputPath = Join-Path $TestDrive 'release'
        $files = @(& "$repositoryPath/scripts/Build-Module.ps1" -OutputPath $outputPath)
        $archive = $files | Where-Object Extension -EQ '.zip'
        $checksum = Get-Content "$($archive.FullName).sha256"
        $checksum | Should -Be "$((Get-FileHash $archive.FullName -Algorithm SHA256).Hash.ToLowerInvariant())  $($archive.Name)"

        $installationPath = Join-Path $TestDrive 'modules'
        Expand-Archive $archive.FullName -DestinationPath $installationPath
        $manifestPath = Join-Path $installationPath "$moduleName/0.2.0/$moduleName.psd1"
        $manifest = Test-ModuleManifest $manifestPath
        $manifest.Name | Should -Be $moduleName
        $manifest.Version | Should -Be ([version]'0.2.0')
        $manifest.Guid | Should -Be $expectedGuid
        $manifest.Guid | Should -Not -Be ([guid]'60742743-bfdd-46c1-bd7a-8dfab61de69e')
        $manifest.Guid | Should -Not -Be ([guid]'bb42e16e-b0af-46be-9ac1-51e2f6bb6e8d')
        $archive.Name | Should -Be "$moduleName.0.2.0.zip"
        Test-Path (Join-Path (Split-Path $manifestPath) 'LICENSE') | Should -BeTrue
        Test-Path (Join-Path $installationPath 'PSRule.Rules.AzureDevOps') | Should -BeFalse
        Test-Path (Join-Path $installationPath 'DevOpsTools.AzureDevOps.Assessment') | Should -BeFalse

        $probePath = Join-Path $TestDrive 'Import-PackagedModule.ps1'
        @'
param($InstallationPath, $ManifestPath)
$ErrorActionPreference = 'Stop'
$env:PSModulePath = $InstallationPath + [IO.Path]::PathSeparator + $env:PSModulePath
$module = Import-Module $ManifestPath -Force -PassThru
Remove-Module $module.Name -Force
$module = Import-Module -FullyQualifiedName @{
    ModuleName = 'DevOpsTools.AzureDevOps.PSRule'
    RequiredVersion = '0.2.0'
    GUID = 'f77fbd3d-03be-4e42-98f3-4c185cc93bba'
} -PassThru
foreach ($name in 'Connect-AzDevOps', 'Export-AzDevOpsRuleData', 'Export-AzDevOpsOrganizationRuleData', 'Export-AzDevOpsAssessmentRun') {
    if ((Get-Command $name).ModuleName -ne $module.Name) { throw "Missing packaged command: $name" }
}
Import-Module PSRule -RequiredVersion 2.9.0
$rules = @(Get-PSRule -Module $module.Name -Culture en)
if ($rules.Count -ne 119) { throw "Unexpected packaged rule count: $($rules.Count)" }
foreach ($rule in $rules) {
    if (-not (Test-Path (Join-Path $module.ModuleBase "en/$($rule.Name).md"))) { throw "Missing packaged help: $($rule.Name)" }
}
'@ | Set-Content $probePath
        & (Get-Process -Id $PID).Path -NoProfile -File $probePath $installationPath $manifestPath
        $LASTEXITCODE | Should -Be 0
    }
}
