# Assessment reporting and migration

`Assessment/catalog.json` contains 117 uniquely identified historical documented controls, plus explicit dispositions for two supplemental runtime rules. Rule-set version is `2026.10.21.1`; severity-policy version is `1.0.0`. The 42 supplied backlog ratings and the replacement secret control are recorded. The separate proposed inventory and 57 broader severity changes were not supplied: their affected controls cannot be inferred. Unspecified ratings remain null/PendingBroaderProposal, preserving the legacy help rating separately.

## Project raw results without rewriting them

```powershell
$raw = @($targets | Invoke-PSRule -Module PSRule.Rules.AzureDevOps -Baseline Baseline.Default -Option $option -Outcome All)
$report = ConvertTo-AzDevOpsAssessment -Result $raw -TargetObject $targets `
    -ScopeId 'organization/project' -Baseline Baseline.Default -Configuration $configuration
$report | ConvertTo-Json -Depth 50 | Set-Content assessment-results.json
```

Use the same original targets, configuration, baseline, and scope as the raw run. Target identity is the existing ObjectType/ObjectName binding. Duplicate identities within one scope are rejected; organization-wide exports must project each project separately because organization settings are repeated in each project export. Do not publish original exports as report artifacts.

Findings preserve raw RuleId, TargetName, outcome, reasons, and PSRule level. Unknown and NotApplicable are explicit assessment states. Run PSRule with Outcome All so skipped evidence remains visible. Raw SARIF stays unchanged and retains each finding. Assessment projection is additional JSON, not a rewrite of SARIF.

Branch existence and enabled-state diagnostics correlate only for the same target. Generic production protection and required human review correlate only when evidence establishes the same absent or disabled gate; an existing automated gate with missing required human review remains a separate requirement. The deprecated secret alias and its replacement share one objective. Other branch-policy requirements remain independent, including enabled-but-insufficient review policies.

Security, Engineering, and Governance remain separate domains. Security weighting uses Low=1, Medium=2, High=4, Critical=8; these are policy weights, not monetary loss or remediation effort. Each objective uses the highest applicable reviewed rating and contributes once. Unknown evidence or unclassified severity prevents a complete SecurityScore. KnownFailedSecurityWeight is explicitly partial, never a substitute for a complete posture score. No effort estimates are fabricated.

## History

Compare-AzDevOpsAssessment returns a numerical delta only when the scope, baseline, rule-set version, severity-policy version, configuration hash, and applicable security-objective denominator agree and both scores are available. Otherwise the delta is null and the change must be annotated as a policy/scope/coverage migration. Existing raw diagnostic identities remain available for longitudinal drill-down.

Old-to-new semantic mapping:

| Historical ID | Current behavior |
| --- | --- |
| NoKeyVaultNoSecrets | Deprecated alias of NoPlainTextSecrets; masked Vsts secrets accepted |
| Six InheritedPermissions IDs | Retained IDs; effective permissions with complete evidence and referenced policy |
| Policy controls | Retained IDs; optional policy applicability and explicit Unknown |
| Branch and production gate IDs | Distinct raw diagnostics; correlated assessment objectives only where justified |

A reduced denominator caused by optional policy, unavailable ACL evidence, baseline selection, or a revised catalog must not be reported as compliance improvement. Dashboard HTML and historical rendering belong to the dashboard repository and are not modified by this branch. Consumers must adopt this reporting contract before presenting revised risk scores.

## Expected migration deltas

| Evidence | Historical diagnostic | Revised diagnostic / assessment |
| --- | --- | --- |
| Masked Vsts secret without Key Vault | NoKeyVaultNoSecrets failed | Both retained secret diagnostics pass; one risk objective |
| Inheritance enabled with no complete ACL/identity evidence | InheritedPermissions failed | Not evaluated / Unknown; coverage gap remains visible |
| Safe complete inherited ACL under policy | InheritedPermissions failed | Pass |
| Missing optional region, billing, human-review, license, or retention policy | Often failed a hard-coded default | NotApplicable; denominator change is annotated |
| Unapproved public project | Fail | Fail; only explicit policy/baseline approval permits it |
| Missing branch protection | Two raw findings | Two raw findings, one same-target High risk objective |
| Automated gate with required human review absent | Separate diagnostics | Generic gate passes, human-review fails; distinct requirements |

The assessment pipeline now includes a trailing directory separator when passing the export root to PSRule 2.9.0. Without it, nested files were not discovered in the regression fixture. The artifact test verifies four raw findings from two project folders and one correlated objective per project. A report with exported targets but no matching detailed result provenance is rejected. Unknown new diagnostic IDs also prevent a complete score until the catalog is updated.

## Configuration key migration

| Previous setting | Referenced policy replacement |
| --- | --- |
| ghasEnabled | assessmentPolicies[Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled].Expected |
| ghasBlockPushesEnabled | assessmentPolicies[Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes].Expected |
| ArtifactMinimumRetentionDays | assessmentPolicies[Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays].Minimum |
| PullRequestRunsMinimumRetentionDays | assessmentPolicies[Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays].Minimum |

Add Reference to each migrated policy. The historical GHAS defaults remain present in legacy baseline files for configuration compatibility, but they do not implicitly activate the new licensed-feature policy. Unconfigured optional controls are NotApplicable. Administrator count keys retain their existing names. Record the administrative/recovery policy reference in the configuration so the history configuration hash changes when the operating model changes.
