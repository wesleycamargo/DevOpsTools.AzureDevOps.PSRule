# Rule quality improvement — implementation plan

> **STATUS:** Proposed only. Do not treat this package as committed or tested. GitHub branch creation was blocked by a `403 Resource not accessible by integration` response on 2026-10-21. No remote files were changed.

**Repository:** `wesleycamargo/PSRule.Rules.AzureDevOps`  
**Base:** `main` at `cd23e9a6da17a1dafd3bb467633547f736be5795` (verify against latest `main` before work).  
**Intended branch:** `fix/assessment-rule-quality-20261021`  
**Scope:** 42 unique rule improvements, plus a separate proposed 117-rule classification inventory. Existing module rules, baselines, and dashboards remain unchanged until changes are reviewed and merged.

## Plan in five phases

| Phase | Work | Deliverable | Validation gate |
|---|---|---|---|
| 0. Prepare | Create a branch from current `main`; inventory effective source rules, baseline selections, test fixtures, collectors, and dashboards; establish expected compliance deltas. | Inventory and baseline snapshot | Branch starts at expected commit; no generated secrets/raw organization exports |
| 1. Correct misleading controls (P1) | Replace six blanket inheritance checks with evidence-based effective permissions; retire no-Key-Vault blanket failure; fix help for two distinct job authorization settings. | Updated PSRule source, help, synthetic fixtures | Safe inheritance passes; excessive permissions fail; legitimate encrypted secrets pass; unavailable ACL data is Unknown/Not evaluated |
| 2. Correlate findings (P1) | Preserve policy-exists vs policy-enabled diagnostics and production-check vs human-approval diagnostics, but introduce root-control/risk-group metadata to stop double-counting. | Scoring metadata + reporting contract | A single missing protection is not weighted multiple times; raw SARIF preserves each finding |
| 3. Applicability + baselines (P2) | Introduce documented Security / Engineering / Governance / Conditional baselines or filters; make region, billing, visibility, licensed product, SSH/OAuth, human approvals, retention, and agent pinning policy-driven. | Baselines and opt-in config with NoExtraLicense/PublicProject compatibility | Not-applicable controls do not count as failed; policy overrides are explicit; default behavior documented and migration-safe |
| 4. Severity calibration (P3 and wider review) | Apply selected severity changes to independent assessment metadata, without equating PSRule `-Level` with four-grade business risk; separately validate the 57 broader proposed changes. | Versioned severity catalog / rule help; policy provenance | 117 catalog entries keyed uniquely; runtime and help severity coherent; High/Critical require a documented exposure rationale |
| 5. Validate and hand over | Run offline unit/Pester suites, optional gated integration with fake fixtures, review SARIF and dashboard snapshots, open PR. | Test evidence + PR | No unexpected rule disappearance, score drift, pipeline regressions, or history identity changes |

## Grounded discoveries that change the earlier recommendation

- **Do not merge the job-auth-scope rules.** Their PowerShell implementations already inspect different fields: `enforceJobAuthScope` (non-release) and `enforceJobAuthScopeForReleases` (release). The non-release help incorrectly repeats the release setting. Fix documentation and test independence.
- **Rule severity has two representations.** PSRule scripts use `-Level` (`Error`, `Warning`, `Information`) while English help files have `severity: Critical/Severe/Important/Moderate/Informational`. The proposed four-level risk scale must not silently change the result contract.
- **Not all source rules are in the 117-rule README list.** For example `Azure.DevOps.Repos.Branch.CommitRecent` and `Azure.DevOps.Organization.Security.Policies.Debug` are present in rule scripts. Enumerate runtime rules and treat debug/hidden rules explicitly.
- **Existing baselines:** `Baseline.Default`, `Baseline.NoExtraLicense`, `Baseline.PublicProject`. Keep their compatibility visible; `Baseline.PublicProject` already excludes project visibility and both status badge rules.
- **Existing Pester tests assert obsolete behavior.** For example `tests/Rules.Unit.Tests.ps1` explicitly expects encrypted `Vsts` secret variables to fail `NoKeyVaultNoSecrets`. Rewrite tests alongside the implementation.

## Required design decisions

1. **Security risk vs maturity:** treat source PSRule findings as immutable diagnostic evidence. Put the assessment severity, applicability, domain, and risk-group mapping in separately versioned configuration.
2. **Root-cause grouping:** correlate same-target `HasBranchPolicy` / `BranchPolicyIsEnabled`, without deleting distinct diagnostics. General production protection vs human-approval checks are separate requirements; correlate only the *same underlying* missing gate.
3. **Effective permissions:** do not infer effective access from an `inheritPermissions` flag; calculate grants/denies with group resolution. When collection lacks enough ACL or identity data, use an explicit unknown/unavailable outcome, not Pass.
4. **Optional policies:** region, time zone, licensed features, public projects, guest access, SSH/OAuth, human approval, and retention require opt-in organizational policy or supported baseline.
5. **Safe migration:** do not remove existing rule IDs abruptly. Deprecate where appropriate, ship old-to-new mappings, document baseline changes, and annotate longitudinal dashboards so a changed denominator is not called compliance improvement.
6. **Scope boundaries:** the rules repository owns collectors, rules, baselines and help. The dashboard repository owns HTML, scoring visualizations, historical projection and effort estimates. Do not modify the dashboard repository in this branch.

## 42-rule backlog

Full rule names are shown below. All entries are **planned**, not implemented.

| # | Priority | Rule | Action | Existing → Proposed risk | Exact change | Acceptance |
|---:|---|---|---|---|---|---|
| 1 | P1 | `Azure.DevOps.Tasks.VariableGroup.NoKeyVaultNoSecrets` | **Replace** | Critical → Medium | Deprecate the rule that rejects any non-Key-Vault secret group. Replace it with evidence-based secret handling checks; encrypted Azure DevOps secret variables must not fail solely for lacking Key Vault. | An encrypted secret variable outside Key Vault is not a failure; demonstrably exposed plaintext secrets still fail; missing collection is Unknown. |
| 2 | P1 | `Azure.DevOps.Pipelines.Core.InheritedPermissions` | **Replace** | Severe → Medium | Retire the unconditional inheritPermissions=false requirement. Evaluate effective edit/run/manage rights and sensitive pipeline privileges. | A correctly limited inherited ACL passes; a user with unauthorized edit/queue/manage permission fails; insufficient ACL evidence is Unknown. |
| 3 | P1 | `Azure.DevOps.Pipelines.Environments.InheritedPermissions` | **Replace** | Severe → Medium | Stop failing on inheritance alone. Check effective administration, check modification, and deployment privileges. | Inherited least-privilege access passes; excessive production deployment or check-admin access fails. |
| 4 | P1 | `Azure.DevOps.Pipelines.Releases.Definition.InheritedPermissions` | **Replace** | Severe → Medium | Evaluate effective release pipeline administration and deployment rights instead of inheritance. | Safe inheritance passes and excessive release privileges fail. |
| 5 | P1 | `Azure.DevOps.Repos.InheritedPermissions` | **Replace** | Severe → Medium | Evaluate effective repository permissions including policy bypass, force-push and permission management instead of forbidding inheritance. | Inherited read access passes; unauthorized dangerous permissions fail. |
| 6 | P1 | `Azure.DevOps.ServiceConnections.InheritedPermissions` | **Replace** | Severe → Medium | Replace blanket inheritance failure with effective service-connection use/admin/authorization checks. | Inherited narrow access passes; unauthorized production endpoint access fails. |
| 7 | P1 | `Azure.DevOps.Tasks.VariableGroup.InheritedPermissions` | **Replace** | Severe → Medium | Replace inheritance prohibition with effective variable-group administration and authorization checks. | Least-privilege inheritance passes; inappropriate secret-group use or administration fails. |
| 8 | P1 | `Azure.DevOps.Repos.Branch.HasBranchPolicy` | **Correlate** | Critical → High | Preserve has-policy diagnostic, but map it to one branch-protection risk objective with IsEnabled. | A branch without policy shows useful diagnostics but contributes only one root-risk finding. |
| 9 | P1 | `Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled` | **Correlate** | Critical → High | Preserve enabled-policy diagnostic. Do not count a missing and disabled policy as independent identical exposures. | Policy absent versus disabled remain distinct details without double-counting. |
| 10 | P1 | `Azure.DevOps.Repos.HasDefaultBranchPolicy` | **Correlate** | Critical → High | Group default-branch policy existence with enabled state in scoring, preserving raw results. | One default-branch protection objective per repository. |
| 11 | P1 | `Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled` | **Correlate** | Critical → High | Maintain enabled-state check; correlate with default-branch existence. | A disabled existing policy reports the right cause; weighted scores remain deduplicated. |
| 12 | P1 | `Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeNonRelease` | **DocsOnly** | Severe → High | Correct documentation: code uses enforceJobAuthScope for non-release; this is already distinct from release. DO NOT merge implementations. | Help cites non-release field; synthetic tests show release and non-release can independently pass/fail. |
| 13 | P1 | `Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeRelease` | **DocsOnly** | Severe → High | Retain the release control using enforceJobAuthScopeForReleases. Correct documentation if it conflates with non-release. | Both rules remain independent and test each target property. |
| 14 | P1 | `Azure.DevOps.Pipelines.Environments.ProductionCheckProtection` | **Correlate** | Severe → High | Keep generic environment check protection distinct from human-approval governance; link both to shared production risk grouping. | Automated checks alone satisfy this specific check when effective; no double charge for one missing gate. |
| 15 | P1 | `Azure.DevOps.Pipelines.Environments.ProductionHumanApproval` | **Conditional** | Severe → High | Require human approval only when an explicit deployment policy mandates it; assess approved equivalent gates when permitted. | Approved automation does not fail an optional manual-approval standard; required human gate absent fails. |
| 16 | P1 | `Azure.DevOps.ServiceConnections.ProductionCheckProtection` | **Correlate** | Severe → High | Retain protection check separately from human approval; correlate common missing production gate. | Missing gate has one primary exposure with distinct drill-down findings. |
| 17 | P1 | `Azure.DevOps.ServiceConnections.ProductionHumanApproval` | **Conditional** | Severe → High | Require human approval only for production connections covered by approved human-review policy. | Unapproved bypass fails; authorized automation is not incorrectly called a critical failure. |
| 18 | P2 | `Azure.DevOps.Organization.GeneralOverview.TimeZoneSet` | **Conditional** | Severe → Low | Stop demanding hard-coded CET. Move to an opt-in organization-configuration policy with an expected time zone parameter. | US/other valid time zones do not fail a general security baseline; explicit time zone policy is evaluated. |
| 19 | P2 | `Azure.DevOps.Organization.GeneralOverview.GeographySet` | **Conditional** | Severe → Low | Move Europe requirement to regional-compliance policy parameter, not universal default. | Regions allowed by a declared residency policy pass; unspecified policy yields Not applicable. |
| 20 | P2 | `Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled` | **Baseline** | Severe → Low | Move out of core security baseline; validate only against approved assignment-billing policy. | Billing preferences cannot change project security posture. |
| 21 | P2 | `Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured` | **Baseline** | Moderate → Low | Move to financial-governance baseline, with explicit expected enable/disable state. | Non-enterprise billing is not a security violation unless prohibited by approved policy. |
| 22 | P2 | `Azure.DevOps.Organization.GeneralOverview.DescriptionSet` | **Baseline** | Moderate → Low | Move to governance/documentation maturity and lower default impact. | Missing org description does not increase measured security exposure. |
| 23 | P2 | `Azure.DevOps.Repos.License` | **Conditional** | Informational → Low | Assess license file only for distributed/open repositories or where licensing policy says it applies. | Private application code with no distribution requirement is Not applicable. |
| 24 | P2 | `Azure.DevOps.Repos.Readme` | **Baseline** | Informational → Low | Keep README completeness under engineering-maturity baseline rather than risk scoring. | Missing README changes maturity but not core security risk. |
| 25 | P2 | `Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled` | **Conditional** | Important → Medium | Treat GHAS enablement as a licensed vendor-specific optional control; security scanning coverage must consider approved equivalents. | Equivalent approved scanning does not cause vendor-product lock-in; disabled license-gated feature is Not applicable in NoExtraLicense. |
| 26 | P2 | `Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes` | **Conditional** | Important → Medium | Require effective push-time secret protection only where mandated, allowing validated alternatives. | Documented equivalent prevention passes or is represented as compensated; license-inapplicable results do not fail. |
| 27 | P2 | `Azure.DevOps.Organization.Security.Policies.DisallowSecureShell` | **Conditional** | Severe → Low | Make SSH prohibition an opt-in authentication policy; SSH with approved controls is permitted. | Approved SSH authentication is not a default Severe finding. |
| 28 | P2 | `Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess` | **Conditional** | Severe → Medium | Policy-driven: distinguish approved guest collaboration from unauthorized external access. | Approved governed guests do not fail automatically; unauthorized exposure fails. |
| 29 | P2 | `Azure.DevOps.Organization.Security.Policies.DisallowOAuthAuthentication` | **Conditional** | Severe → Medium | Replace unconditional OAuth ban with policy-approved third-party application authentication. | Approved OAuth integrations do not fail general security baseline. |
| 30 | P2 | `Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess` | **Conditional** | Severe → High | Respect approved public-project use cases, using explicit public-project baseline or documented exception. | Approved public projects pass relevant public settings; inadvertent anonymous exposure fails. |
| 31 | P2 | `Azure.DevOps.Project.Visibility` | **Conditional** | Critical → High | Public visibility is permissible only when explicitly approved; preserve high severity for exposure of confidential assets. | Approved public project passes via explicit baseline; confidential public project fails. |
| 32 | P2 | `Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest` | **Conditional** | Important → Low | Replace universal pinning with approved supported image and lifecycle policy, including exceptions. | Supported intentionally floating image passes; EOL/unapproved agent fails where evidence is available. |
| 33 | P2 | `Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays` | **Conditional** | Severe → Medium | Check a configured retention threshold justified by actual evidence/audit requirements. | Approved retention profile passes regardless of hard-coded days; absent profile is Not applicable. |
| 34 | P2 | `Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays` | **Conditional** | Severe → Medium | Make PR run retention policy configurable for its evidence class. | Correct per-class retention passes; inappropriate fixed default no longer generates risk. |
| 35 | P3 | `Azure.DevOps.Pipelines.Settings.StatusBadgesPrivate` | **Severity** | Severe → Low | Normalize to Low by default; only escalate when badge detail reveals sensitive operational information. | Badge exposure alone does not count as Severe security risk. |
| 36 | P3 | `Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess` | **Severity** | Severe → Low | Normalize badge visibility to Low by default; keep control for disclosure review. | Organization-wide badge visibility does not dominate weighted risk. |
| 37 | P3 | `Azure.DevOps.Groups.ProjectAdmins.MaxMembers` | **Severity** | Severe → Medium | Downgrade to Medium and allow threshold/approved administrative operating model; assess privilege quality. | Five justified admins no longer automatically imply Severe security risk. |
| 38 | P3 | `Azure.DevOps.Groups.ProjectAdmins.MinMembers` | **Severity** | Severe → Medium | Downgrade to Medium continuity control; permit centralized recovery/break-glass arrangements. | Legitimate one-admin-plus-break-glass patterns can be assessed contextually. |
| 39 | P3 | `Azure.DevOps.Organization.GeneralBillingSettings.SubscriptionActive` | **Severity** | Severe → Medium | Reclassify as business continuity, Medium unless service interruption is demonstrated. | Inactive billing is not reported as a severe security vulnerability. |
| 40 | P3 | `Azure.DevOps.Organization.GeneralOverview.OwnerSet` | **Severity** | Severe → Medium | Downgrade to Medium governance/accountability control. | Missing owner remains actionable without inflating security score. |
| 41 | P3 | `Azure.DevOps.Organization.Security.Policies.DisallowFeedbackCollection` | **Severity** | Moderate → Low | Downgrade to Low privacy preference unless policy/legal context requires greater priority. | Privacy setting is not misclassified as technical security exposure. |
| 42 | P3 | `Azure.DevOps.ServiceConnections.ClassicAzure` | **Severity** | Critical → High | Downgrade to High by default; escalate only when exposed scope/permissions support Critical. | Legacy Classic Azure without demonstrated exposure does not automatically become Critical. |

## Prepared but not committed — preview implementation files

The attached package includes four *opt-in* PSRule review baselines (`Baseline.SecurityReview`, `Baseline.EngineeringReview`, `Baseline.GovernanceReview`, and `Baseline.ConditionalReview`). Their explicit `rule.include` lists partition the 110 non-legacy documented controls by proposed assessment purpose; seven blanket inheritance/Key-Vault checks remain outside these previews. The existing three baselines remain unmodified. The package also includes a corrected help document for the non-release authorization-scope rule and a Pester metadata consistency test. These are **uncommitted prototypes**, not completion of the 42-rule implementation.

**No `pwsh` / Pester execution was possible in this environment.** Validate discoverability with the module and run Unit and relevant Integration fixtures on the branch before switching any pipeline to the new baselines. A proposed risk level in JSON is not automatically consumed by the existing dashboard.

## Acceptance and test strategy

| Verification | Evidence / expected behavior |
|---|---|
| Inventory completeness | Every documented rule ID maps to an actual source rule or is marked as legacy; every emitted source rule is documented or intentionally hidden. |
| Secret handling | A Vsts variable `{ isSecret:true, value:null }` is not failed merely for not using Key Vault; a demonstrably unmasked credential is not accepted as safe. |
| Permission checks | Cover direct and inherited ACLs, group and nested-group membership, explicit deny, administrative bypass, authorized principals, missing data. |
| Branch protections | Missing, disabled, and enabled-but-insufficient policies remain distinguishable; project score groups correlated exposures. |
| Scope settings | Each `LimitJobAuthScope*` rule checks the intended distinct setting with tests where one is true and the other false. |
| Conditional baselines | NoExtraLicense/PublicProject continue to work; organization policies explicitly set applicability and expected values. |
| Reporting | Run history identifies rule-version and severity-policy-version; migration can compare legacy and revised controls without false improvement. |
| PSRule/Pester | Run `tests/Run-Tests.ps1` with `-TestType Unit` (verify actual parameters in repo) and relevant rule suites; integration tests only where credentials/test org are authorized. |
| No secrets | No PATs, exports, tokens, `.env`, real users, or organization configuration committed as test artifacts. |

## Suggested local Git workflow (after write permissions are restored)

```bash
git fetch origin main
git switch main
git pull --ff-only origin main
git switch -c fix/assessment-rule-quality-20261021
# Apply source/test/help and baseline improvements in small reviewable commits.
# Add the attached docs/assessment/ files to the checkout.
git add docs/assessment
git commit -m "docs: plan rule-quality remediation and track classifications"
# Run tests and open PR; do not push to main.
```

## Proposed commit boundaries

1. `docs: plan assessment rule-quality improvements`
2. `fix: replace misleading variable group and inherited-permission checks`
3. `fix: document independent pipeline job authorization settings`
4. `feat: correlate branch and production protection risk objectives`
5. `feat: introduce policy-driven applicability and assessment baselines`
6. `chore: publish risk-severity metadata and adjust rule help`
7. `test: cover rule regressions and report migration`

## Explicit non-goals

- No updates to `main`, existing agent branches, dashboard HTML, real Azure DevOps settings, or production environments.
- No fabricated remediation effort estimates; Unknown remains Unknown until measured.
- No risk/severity claim based on documentation alone without a verified control outcome.

## Current blocker

GitHub create-branch request was rejected: `403 Resource not accessible by integration`. Reauthorize the GitHub integration with repository write rights or create the intended branch through another authorized workflow; then apply and test the proposed changes. This package is not itself a Git commit.

## Execution progress

- [x] Verify current remote main and create isolated requested branch.
- [x] Inventory runtime rules, documented controls, collectors, and baseline selections (117 documented, 119 retained runtime IDs; migration deltas documented).
- [x] Replace secret and six inherited permission checks with evidence-based outcomes (targeted and full offline tests passed).
- [x] Correct job authorization help and verify independent settings (4 synthetic cases passed).
- [x] Add versioned assessment catalog and risk correlation contract (117 unique entries; same-target correlation; raw SARIF preserved; unknown ratings explicit).
- [x] Implement policy applicability and review baselines with legacy compatibility (17 policy-aware controls, four discoverable review baselines, PublicProject/NoExtraLicense regression tests).
- [ ] Calibrate assessment severity and document migration (42 supplied changes and replacement secret rating implemented; separate 57-change proposal still missing).
- [ ] Run offline suites, authorized pipeline validation, and open PR.

## Handover

Current: Implementation now covers the supplied 42-rule backlog, with versioned assessment metadata, policy applicability, review baselines, source/identity preservation, and a per-project pipeline reporting bridge. Full offline suite passed 159 tests (0 failed, 635 live/integration tests not selected) using Pester 5.7.1 and PSRule 2.9.0. Result XML: /tmp/assessment-quality-phase3-final.xml. Raw SARIF artifact test retains four branch findings across two project scopes while projecting one root objective per project; original payloads are excluded. Pipeline template regression tests cover the additional report, incomplete collection, assertion failure, and fresh exports. CI now uses pinned test requirements, includes Assessment files in triggers, and exits unsuccessfully on failed tests.
Next: Publish the branch and open a draft PR; run branch pipeline validation and inspect its artifacts. Perform independent requirement-by-requirement implementation validation, including collector semantics and the remaining broader severity proposal.
Blockers: GitHub connector create-branch again returned 403 Resource not accessible by integration; gh has no authenticated host. Git transport publication still to be attempted after the verified milestone is committed. The separate proposed 117-entry inventory/57 broader severity changes were not supplied; user was asked for their location. Those missing proposed ratings remain explicitly null/PendingBroaderProposal rather than being fabricated. Azure CLI read access to pipeline 14 was verified; it references this GitHub repository and pipelines/psrule-assessment.yml.
Remaining validation: Remote branch/PR and pipeline results; independent final audit; broader severity proposal. Do not mark the overall goal complete.
