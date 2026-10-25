# GitHub module releases

After a release is published, download the module ZIP and its `.sha256` file from
[GitHub Releases](https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/releases).
The ZIP contains only the module, rule help, and license under
`DevOpsTools.AzureDevOps.PSRule/<version>/`.

For version 0.2.0, run these commands from the download directory in PowerShell 7:

```powershell
$archive = './DevOpsTools.AzureDevOps.PSRule.0.2.0.zip'
$expectedHash = (Get-Content "$archive.sha256").Split(' ')[0]
if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne $expectedHash) {
    throw 'Module archive checksum does not match.'
}
Install-Module PSRule -RequiredVersion 2.9.0 -Scope CurrentUser
$moduleDirectory = ($env:PSModulePath -split [IO.Path]::PathSeparator)[0]
New-Item -Path $moduleDirectory -ItemType Directory -Force | Out-Null
Expand-Archive -Path $archive -DestinationPath $moduleDirectory -Force
Import-Module DevOpsTools.AzureDevOps.PSRule -RequiredVersion 0.2.0 -Force
```

To build the same package from a checkout, run `./scripts/Build-Module.ps1`.
The ZIP and SHA-256 file are written to `.local/releases/` by default. Verify the
archive by extracting it and importing its manifest before uploading both files to
a release whose tag matches the manifest version.

## Validate and publish

The `.github/workflows/publish-on-release.yml` GitHub Actions workflow runs on
every push to `main`. It validates the manifest, runs pinned offline tests,
builds the ZIP and checksum, and publishes the declared module version to
PowerShell Gallery. If that exact version is already published, validation and
packaging still run, but publication is skipped. Gallery lookup failures stop
publication. Runs are serialized to avoid concurrent publication attempts.

To publish a new version, update the module manifest version before merging to
`main`. Automatic publication does not require or create a Git tag. The existing
`0.2.0` package is not republished when this workflow is enabled.

Manual execution remains available: supply an existing tag matching the manifest
version, such as `v0.2.0`. The manual `publish` input defaults to `false` for
validation only; enable it to publish a version that is not already in Gallery.
Both publication modes use the repository secret `PS_GALLERY_KEY`. Publishing
requires credentials authorized for the package name. GitHub releases do not
trigger this workflow.
The published source includes `LICENSE`; its manifest links to the public GPLv3
text so package recipients can read the terms directly.
The former Azure Pipelines publisher has been retired; live pipeline definitions
and existing Azure Artifacts packages are managed separately.

The new package starts at `0.2.0` with GUID
`f77fbd3d-03be-4e42-98f3-4c185cc93bba`. It supersedes
`DevOpsTools.AzureDevOps.Assessment` 0.1.0, whose GUID is
`60742743-bfdd-46c1-bd7a-8dfab61de69e`. Preserve the new GUID across subsequent
versions. See [migration instructions](../README.md#migration-to-the-new-module-name)
for consumer changes. The public original repository was renamed to
`wesleycamargo/DevOpsTools.AzureDevOps.PSRule`, preserving its commit history,
branches, pull requests, and historical tags. The temporary private copy is retained
as `DevOpsTools.AzureDevOps.PSRule.Backup`. The existing `v0.1.0` tag still identifies the
Assessment release; it must not be moved to the new package. The published
Assessment package remains unchanged. Earlier releases of
`PSRule.Rules.AzureDevOps` remain in [the predecessor repository](https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/releases).
