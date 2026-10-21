## [Unreleased]

### Added

- Four opt-in assessment review baselines, a 117-control catalog, and versioned assessment JSON with same-target risk correlation and explicit Unknown/NotApplicable coverage.
- Referenced policies for optional region, billing, licensing, authentication, human approval, retention, and agent lifecycle controls. Assessment policy 1.1.0 applies the supplied 117-rule classification inventory with preserved provenance and applicability guidance.

- Export of **Organization Settings** in `Export-AzDevOpsOrganizationRuleData` to extend coverage of organizational rule data.

### Improved

- Enhanced error handling to allow the export process to continue even if individual export steps fail.
- Logging messages now provide clearer and more structured feedback during execution.

### Fixed

- Assessment pipeline export discovery now includes nested project files and retains both raw SARIF and versioned per-project reports. Policy or denominator changes invalidate numerical history comparisons.

- Masked Azure DevOps variable-group secrets no longer require Key Vault. The historical `NoKeyVaultNoSecrets` ID remains a deprecated alias; unavailable data is not evaluated.
- Six `InheritedPermissions` controls now assess complete effective permission evidence against a referenced policy, including nested groups, denies, and administrative bypass. Missing evidence or policy is Unknown, rather than a pass or an inheritance failure.

- `Export-AzDevOpsRuleData` no longer requires `-Organization` and `-OrganizationId`; both default to the connection, and an explicit `-OrganizationId` is now used instead of being discarded.
- `Connect-AzDevOps -AccessToken` no longer requires `-OrganizationId`.
- The organization readers (`Read-AdoOrganizationPipelinesSettings`, `-GeneralOverview`, `-SecurityPolicies`, `-GeneralBillingSettings`) accept a bare access token as well as a full `Bearer` header value.
- `Get-AzDevOpsPipelineYaml` throws on authentication failures instead of returning nothing, and no longer returns an HTML sign-in page as pipeline YAML.
- `Export-AdoOrganizationPipelinesSettings` uses the same "not connected" message as the other collectors.
- The `Baseline.PublicProject` baseline also excludes `Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess`.

### Testing

- `tests/Run-Tests.ps1` selects `Unit`, `Integration`, or `Authentication` tests and fills missing `ADO_*` variables from the Azure CLI login for live runs.
- Live authentication tests moved to `tests/Authentication.Tests.ps1`.
- `tests/Initialize-IntegrationTestData.ps1` creates the Azure DevOps test data the Integration tests expect.
- The dev container image installs the pinned Pester and PSRule versions, and `.vscode/launch.json` has one entry per test type.
