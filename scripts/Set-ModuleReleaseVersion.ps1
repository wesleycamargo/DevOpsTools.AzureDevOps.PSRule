[CmdletBinding()]
param (
    [string]$ManifestPath = (Join-Path $PSScriptRoot '../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1'),

    [string[]]$PullRequestLabels = @()
)

$ErrorActionPreference = 'Stop'
$bump = 'minor'
if ($PullRequestLabels -contains 'major' -and $PullRequestLabels -contains 'patch') {
    throw 'A pull request cannot have both major and patch version labels.'
}
if ($PullRequestLabels -contains 'major') { $bump = 'major' }
if ($PullRequestLabels -contains 'patch') { $bump = 'patch' }

$manifest = Import-PowerShellDataFile -Path $ManifestPath
if ($manifest.PrivateData.PSData.Prerelease) {
    throw 'Automatic version bumps do not support prerelease manifests; use the manual tagged workflow.'
}
$sourceVersion = [version]$manifest.ModuleVersion
$published = Find-Module -Name 'DevOpsTools.AzureDevOps.PSRule' -Repository PSGallery -ErrorAction Stop
$baseVersion = [version]$published.Version
if ($sourceVersion -gt $baseVersion) { $baseVersion = $sourceVersion }

$version = switch ($bump) {
    'major' { '{0}.0.0' -f ($baseVersion.Major + 1) }
    'minor' { '{0}.{1}.0' -f $baseVersion.Major, ($baseVersion.Minor + 1) }
    'patch' { '{0}.{1}.{2}' -f $baseVersion.Major, $baseVersion.Minor, ($baseVersion.Build + 1) }
}
# Update-ModuleManifest removes wildcard exports; change only the version assignment.
$content = Get-Content -LiteralPath $ManifestPath -Raw
$pattern = [regex]'(?im)^(?<prefix>[ \t]*ModuleVersion[ \t]*=[ \t]*)(?<quote>[''"])[^''"\r\n]+\k<quote>'
$assignments = $pattern.Matches($content)
if ($assignments.Count -ne 1) { throw 'Expected exactly one quoted ModuleVersion assignment in the manifest.' }
$assignment = $assignments[0]
$replacement = $assignment.Groups['prefix'].Value + $assignment.Groups['quote'].Value + $version + $assignment.Groups['quote'].Value
$updated = $content.Remove($assignment.Index, $assignment.Length).Insert($assignment.Index, $replacement)
Set-Content -LiteralPath $ManifestPath -Value $updated -Encoding utf8 -NoNewline
[pscustomobject]@{
    Bump = $bump
    BaseVersion = $baseVersion.ToString()
    Version = $version
}
