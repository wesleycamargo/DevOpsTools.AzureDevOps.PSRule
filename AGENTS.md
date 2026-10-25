# Repository Guidelines

## Project Structure & Module Organization

The PowerShell module lives in `src/DevOpsTools.AzureDevOps.Assessment/`. Its manifest and loader sit beside `Functions/`, `Classes/`, and `rules/`; `en/` and `nl/` contain localized rule help. Keep API retrieval and JSON export functions separate, grouped by object type. Aggregate project exports through `Export-AzDevOpsRuleData`.

Pester tests live in `tests/`. Supporting reports and utilities are in `src/reports/` and `src/helper-functions/`. Use `docs/` for guidance, `example/` for sample configurations, and `assets/media/` for images. CI configuration is in `.github/workflows/`; `pipelines/` contains Azure DevOps pipeline configuration.

## Build, Test, and Development Commands

Run these commands in PowerShell from the repository root:

- `(Import-PowerShellDataFile tests/requirements.psd1).GetEnumerator() | ForEach-Object { Install-Module $_.Key -RequiredVersion $_.Value -Scope CurrentUser -Force -SkipPublisherCheck }`: install the pinned PSRule and Pester versions (the dev container image already has them). Install `PSScriptAnalyzer` separately for style checks.
- `Import-Module ./src/DevOpsTools.AzureDevOps.Assessment/DevOpsTools.AzureDevOps.Assessment.psd1 -Force`: load the local module directly; no compilation step is required.
- `./tests/Run-Tests.ps1 -TestType Unit|Integration|Authentication`: run one test set (default `Unit`). Do not dot-source it; it exits the session with the failure count. VS Code has a launch entry per set.
- `Invoke-ScriptAnalyzer -Path ./src -Recurse -Settings ./src/PSScriptAnalyzerSettings.psd1`: check PowerShell style locally. This check is currently disabled in module CI.

## Coding Style & Naming Conventions

Match surrounding PowerShell style, generally four-space indentation. Use Verb-Noun function names such as `Connect-AzDevOps`, object-oriented filenames such as `DevOps.Repos.ps1`, and rule identifiers such as `Azure.DevOps.Repos.HasDefaultBranchPolicy`. The analyzer settings exclude `PSUseSingularNouns`. Update corresponding localized help when changing rule behavior.

## Testing Guidelines

Add Pester tests for every rule and function; rule tests must cover passing and failing cases. Name files `DevOps.<Area>.Tests.ps1` or `Rules.<Area>.Tests.ps1`. The project targets near 100% coverage; CI collects coverage for functions and classes.

Tag tests `Unit` (offline, no credentials), `Integration` (live Azure DevOps data), or `Authentication` (live `Connect-AzDevOps` modes, in `tests/Authentication.Tests.ps1`). For live runs, `Run-Tests.ps1` fills any unset `ADO_*` variable: organization `ai-experiments`, project `PSRule.Rules.AzureDevOps.Tests` (override with `-Organization`/`-Project`), export directory `tests/outExport`, and all PAT and access-token variables from the `az login` token. Service principal tests need `ADO_CLIENT_ID`, `ADO_CLIENT_SECRET`, and `ADO_TENANT_ID`; managed identity tests only run on Azure-hosted agents.

Integration tests expect the resources created by `tests/Initialize-IntegrationTestData.ps1 -Organization <org> -Project <project>`, which is idempotent. Resolve test resources by name, never by fixed ID or list position. Each live rule test file creates its own exports in Pester's `TestDrive`. See `docs/testing.md` for test selections and prerequisites, and `docs/test-repair-phases.md` for known external blockers.

## Commit & Pull Request Guidelines

Always create Git worktrees under `.worktrees/<task-name>/` in the primary repository checkout. When creating a worktree from another worktree, use the primary checkout's `.worktrees/` directory.

Recent history uses descriptive subjects, often with PR numbers. `CONTRIBUTING.md` explicitly prefers Conventional Commits, for example `fix: handle uninitialized repositories`.

Fork the repository, create a focused branch, and submit a PR with the behavior change, related issues, and validation results. Ensure tests pass before submission. Follow `CODE_OF_CONDUCT.md`; keep credentials and sensitive export data out of commits.
