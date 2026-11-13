# GitHub module releases

After a release is published, download the module ZIP and its `.sha256` file from
[GitHub Releases](https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/releases).
The ZIP contains only the module, rule help, and license under
`DevOpsTools.AzureDevOps.PSRule/<version>/`.

For version 0.2.1, run these commands from the download directory in PowerShell 7:

```powershell
$archive = './DevOpsTools.AzureDevOps.PSRule.0.2.1.zip'
$expectedHash = (Get-Content "$archive.sha256").Split(' ')[0]
if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne $expectedHash) {
    throw 'Module archive checksum does not match.'
}
Install-Module PSRule -RequiredVersion 2.9.0 -Scope CurrentUser
$moduleDirectory = ($env:PSModulePath -split [IO.Path]::PathSeparator)[0]
New-Item -Path $moduleDirectory -ItemType Directory -Force | Out-Null
Expand-Archive -Path $archive -DestinationPath $moduleDirectory -Force
Import-Module DevOpsTools.AzureDevOps.PSRule -RequiredVersion 0.2.1 -Force
```

To build the same package from a checkout, run `./scripts/Build-Module.ps1`.
The ZIP and SHA-256 file are written to `.local/releases/` by default. Verify the
archive by extracting it and importing its manifest before uploading both files to
a release whose tag matches the manifest version.

## Validate and publish

The `.github/workflows/publish-on-release.yml` GitHub Actions workflow runs on
every push to `main`. Before validation, it automatically bumps the module
version in the runner's checkout. It uses the higher of the checked-in manifest
version and the latest stable PowerShell Gallery version as its starting point.
You do not need to edit the manifest before merging a pull request.

The default bump is **minor**. To override it, apply a GitHub **pull request
label** before merging (these are labels, not Git tags):

| PR labels | Bump | Example starting at `0.2.2` |
| --- | --- | --- |
| No version label, or unrelated labels | Minor | `0.3.0` |
| `major` | Major | `1.0.0` |
| `patch` | Patch | `0.2.3` |
| Both `major` and `patch` | Reject the run | No package published |

Label comparisons are case-insensitive. The workflow reads the merged PR
associated with the triggering commit, targeting this repository's `main`.
A direct push without such a PR defaults to minor. GitHub label lookup and
Gallery lookup failures stop publication rather than guessing a bump or base
version. Automatic bumps reject prerelease manifests; use manual tagged
validation/publication for those.

After bumping, the workflow validates the manifest, runs pinned offline tests,
builds the ZIP and checksum, and publishes that same version to PowerShell
Gallery. Existing package versions are never overwritten. Runs are serialized
to avoid concurrent publication attempts.

The bump applies only to the package and runner checkout: it does **not** commit
to `main`, create a Git tag, or create a GitHub release. The checked-in manifest
can therefore be older than the published package. Re-running a completed push
run calculates another bump from the then-current Gallery version and can
publish another version of the same source; it is not an idempotent retry.

Manual execution remains available: supply an existing tag matching the manifest
version, such as `v0.2.1`. The manual `publish` input defaults to `false` for
validation only; enable it to publish a version that is not already in Gallery.
Manual runs do not auto-bump: the selected tag's manifest remains authoritative,
and an already published version is skipped.
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
