# Assessment reporting and migration

`Assessment/catalog.json` contains 117 uniquely identified historical documented controls, plus explicit dispositions for two supplemental runtime rules. Rule-set version is `2026.10.21.2`; severity-policy version is `1.1.0`. All 117 classifications now match the user-supplied `proposed-rule-risk-policy.json`; its original draft and the 42-rule backlog are preserved in this directory as provenance. The draft itself is not loaded at runtime. Legacy help severity and PSRule levels are preserved separately.

Version 1.1.0 fills 74 previously unclassified ratings, adopts 17 supplied domain assignments, and changes the plaintext-secret replacement from Medium to Critical. Its deprecated alias retains the proposed Medium rating; same-target correlation uses the maximum applicable weight once. These are policy migrations, not evidence that security posture improved. `ApplicabilityGuidance` preserves the proposal's evidence caveats; a classification does not prove actual exploitability.

The supplied inventory covers all 117 controls but does not identify a standalone set of 57 changes. Validation therefore compares every ID, original severity, proposed rating, domain, and rationale rather than inferring an unspecified subset. The implemented review selections include the six corrected permission controls (the draft excluded their legacy implementations), omit the deprecated secret alias, keep restrictive public-exposure defaults in Security, and select opt-in controls through Conditional. Domain assignments follow the proposal where it names Security, Engineering, or Governance. Conditional and Legacy are selection/migration categories, so their implemented risk domains remain explicit in the catalog.

## Project raw results without rewriting them

```powershell
$raw = @($targets | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Baseline Baseline.Default -Option $option -Outcome All)
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

PSRule 2.9 assertion output omits precondition results from `ResultVariable`, even with `-Outcome All`. The pipeline retains its SARIF assertion pass and evaluates the same immutable export with `Invoke-PSRule -Outcome All` for the assessment projection. This preserves Unknown permission evidence and NotApplicable optional policies in the JSON report.
