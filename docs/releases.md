# GitHub module releases

After a release is published, download the module ZIP and its `.sha256` file from
[GitHub Releases](https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/releases).
The ZIP contains only the module, rule help, and license under
`DevOpsTools.AzureDevOps.Assessment/<version>/`.

For version 0.1.0, run these commands from the download directory in PowerShell 7:

```powershell
$archive = './DevOpsTools.AzureDevOps.Assessment.0.1.0.zip'
$expectedHash = (Get-Content "$archive.sha256").Split(' ')[0]
if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne $expectedHash) {
    throw 'Module archive checksum does not match.'
}
Install-Module PSRule -RequiredVersion 2.9.0 -Scope CurrentUser
$moduleDirectory = ($env:PSModulePath -split [IO.Path]::PathSeparator)[0]
New-Item -Path $moduleDirectory -ItemType Directory -Force | Out-Null
Expand-Archive -Path $archive -DestinationPath $moduleDirectory -Force
Import-Module DevOpsTools.AzureDevOps.Assessment -RequiredVersion 0.1.0 -Force
```

To build the same package from a checkout, run `./scripts/Build-Module.ps1`.
The ZIP and SHA-256 file are written to `.local/releases/` by default. Verify the
archive by extracting it and importing its manifest before uploading both files to
a release whose tag matches the manifest version.

## Validate and publish

The manual `.github/workflows/publish-on-release.yml` GitHub Actions workflow
checks out an existing tag, validates its version against the manifest, runs
pinned offline tests, builds the ZIP and checksum, and retains validation
artifacts. For this package's initial version, use tag `v0.1.0` on a commit
containing the renamed module. Historical tags still contain the old package.

The `publish` input defaults to `false`. Enable it to publish the validated
`DevOpsTools.AzureDevOps.Assessment` package to PowerShell Gallery using the
repository secret `PS_GALLERY_KEY`. Publishing requires credentials authorized
for the new package name. GitHub releases do not automatically publish to Gallery.
The published source includes `LICENSE`; its manifest links to the public GPLv3
text so recipients can read the terms without access to the private repository.
The former Azure Pipelines publisher has been retired; live pipeline definitions
and existing Azure Artifacts packages are managed separately.

The new package starts at `0.1.0` with GUID
`60742743-bfdd-46c1-bd7a-8dfab61de69e`, replacing the old package's `0.5.12`
version sequence and GUID `bb42e16e-b0af-46be-9ac1-51e2f6bb6e8d`. Preserve the new
GUID across subsequent versions. See [migration instructions](../README.md#migration-to-the-new-module-name)
for consumer changes. The private repository `wesleycamargo/DevOpsTools.AzureDevOps.Assessment`
preserves the predecessor repository's commit history. Historical tags and release
assets remain in [the predecessor repository](https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/releases);
new releases belong to the new repository.
