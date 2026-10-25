[CmdletBinding()]
param (
    [string]$OutputPath = (Join-Path $PSScriptRoot '../.local/releases')
)

$ErrorActionPreference = 'Stop'
$moduleName = 'DevOpsTools.AzureDevOps.PSRule'
$repositoryPath = Split-Path $PSScriptRoot -Parent
$sourcePath = Join-Path $repositoryPath "src/$moduleName"
$manifest = Test-ModuleManifest -Path (Join-Path $sourcePath "$moduleName.psd1")
$version = $manifest.Version.ToString()
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
$outputDirectory = (Resolve-Path $OutputPath).Path
$archivePath = Join-Path $outputDirectory "$moduleName.$version.zip"
$stagingPath = Join-Path ([IO.Path]::GetTempPath()) ('psrule-package-' + [guid]::NewGuid().ToString())

try {
    $versionPath = Join-Path $stagingPath "$moduleName/$version"
    New-Item -Path $versionPath -ItemType Directory -Force | Out-Null
    Copy-Item -Path (Join-Path $sourcePath '*') -Destination $versionPath -Recurse
    Test-ModuleManifest -Path (Join-Path $versionPath "$moduleName.psd1") | Out-Null
    Compress-Archive -Path (Join-Path $stagingPath $moduleName) -DestinationPath $archivePath -Force
    $checksumPath = "$archivePath.sha256"
    $hash = (Get-FileHash -Path $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $([IO.Path]::GetFileName($archivePath))" | Set-Content -Path $checksumPath -Encoding ascii
    Get-Item -Path $archivePath, $checksumPath
}
finally {
    Remove-Item -Path $stagingPath -Recurse -Force
}
