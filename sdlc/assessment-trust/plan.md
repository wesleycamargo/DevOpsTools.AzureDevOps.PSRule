# Implementation Plan: Trustworthy Azure DevOps assessments

## Approach
Use isolated fix/assessment-trust worktrees in both repositories. Add focused failing regressions before corrections. Preserve uncommitted dashboard deployment work in the primary checkout. Use existing PowerShell/PSRule boundaries.

## Tasks
1. Policy enforcement and scope regression tests and corrections. Status: completed.
2. Pagination, file errors, organization completeness and authentication regressions and corrections. Status: completed.
3. Production applicability and secret precision with localized help. Status: completed.
4. Strict dashboard integration and regressions. Status: completed.
5. Shared pinned CI, triggers, failure artifacts and manual publishing contract. Status: completed.
6. Offline suites, parsing, package validation, live checks, branch delivery and candidate pipeline runs. Status: completed; final CI and review handover pending.

## Validation
Run focused Pester cases red then green; run both full offline suites after changes. Verify failure exit in a child process, parse all changed PowerShell, build/import package, and diff-check both repositories. Keep live API checks and deployment evidence distinct from offline results. Verify candidate pipeline sources before queueing; do not merge main.

## Handover
Current: Corrections implemented and review branches pushed. Main merges require user approval. Primary checkout deployment changes remain untouched.
Next: Complete final CI after removing unused SonarCloud configuration and finalize the companion pull requests.
Blockers: No implementation blocker. The older broad live integration suite remains non-green due to missing/inaccessible empty-project fixtures and Linux filename-case mismatches; affected live regressions pass independently. The interactive Azure login is tenant-only, so portal/workbook queries cannot be independently repeated with that identity; the pipeline service identity verified ingestion successfully.
Evidence: Initial boundary tests reproduced 13 failures. Full offline coverage run passed 131 tests with 62.57% command coverage; the later recursive-input regression brings current CI to 132 tests. Dashboard plus preserved local publisher suite passes 15 tests. Affected live authentication/applicability tests pass 31 cases; Amsterdam timezone regression passes. Recursive assessment pipeline tests pass 5 cases and final CI contract tests pass 3 cases. All module PowerShell parses. Package builds, checksum verifies and extracted manifest imports. Live forced pagination returns all four projects visible to the CLI identity with one per page. Strict fixture collection is Complete for both project and organization scopes.
Live-discovered corrections: The configured organization ID was actually a project ID; verified organization instance ID is 5e433049-1396-4a9d-80b2-33dc2f1e98af. Dashboard resolves it from connectionData; the rules pipeline configuration is corrected. Organization policy validation now normalizes whitespace so canonical API names are recognized without relaxing missing-field checks. Empty production service-connection check lists fail.
Candidate delivery: Rules PR https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/pull/1 and dashboard PR https://github.com/wesleycamargo/PSRule.Dashboards.AzureDevOps_/pull/1. Classic workbook pipeline 17 is revision 11 with updated script snapshots; default branches remain main. Temporary validation agent was unregistered after candidate runs.
Live workbook run: https://dev.azure.com/ai-experiments/PSRule.Rules.AzureDevOps/_build/results?buildId=113 succeeded, including HTML report publication and ingestion verification. It evaluated 645 checkpoints: 388 failed controls, 257 passed, zero execution errors. Log Analytics matched those counts exactly. Retained collection-status.json reports Complete for seven service-identity-visible projects and four organization collectors.
Live advisory run: Run 114 exposed a zero-evaluation bug in recursive input selection. After correction, https://dev.azure.com/ai-experiments/PSRule.Rules.AzureDevOps/_build/results?buildId=115 evaluated the same 645 checkpoints with zero execution errors and finished SucceededWithIssues as intended for advisory findings. This is not a blocking compliance gate.
SonarCloud: Removed the obsolete upstream job and sonar-project.properties because the user confirmed no SonarCloud service is used. No token or service provisioning is needed.
