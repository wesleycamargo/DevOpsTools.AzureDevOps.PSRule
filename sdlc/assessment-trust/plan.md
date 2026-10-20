# Implementation Plan: Trustworthy Azure DevOps assessments

## Approach
Use isolated fix/assessment-trust worktrees in both repositories. Add focused failing regressions before corrections. Preserve uncommitted dashboard deployment work in the primary checkout. Use existing PowerShell/PSRule boundaries.

## Tasks
1. Policy enforcement and scope regression tests and corrections. Status: completed.
2. Pagination, file errors, organization completeness and authentication regressions and corrections. Status: completed.
3. Production applicability and secret precision with localized help. Status: completed.
4. Strict dashboard integration and regressions. Status: completed.
5. Shared pinned CI, triggers, failure artifacts and manual publishing contract. Status: completed.
6. Offline suites, parsing, package validation, live checks, branch delivery and candidate pipeline runs. Status: in-progress.

## Validation
Run focused Pester cases red then green; run both full offline suites after changes. Verify failure exit in a child process, parse all changed PowerShell, build/import package, and diff-check both repositories. Keep live API checks and deployment evidence distinct from offline results. Verify candidate pipeline sources before queueing; do not merge main.

## Handover
Current: Implementation complete; validating and preparing delivery.
Next: Run final coverage suite, push review branches, update classic pipeline 17's script snapshot and queue pinned candidate runs without changing its default main branch.
Blockers: None confirmed. Git credential helper provides push and GitHub API access; Azure DevOps update/queue access still to be exercised.
Evidence: Initial boundary tests reproduced 13 failures. Latest full offline run passed 126 tests; subsequent two completeness regressions and three production applicability cases pass. Dashboard plus preserved local publisher suite passes 15 tests. All module PowerShell parses. Package builds, checksum verifies and extracted manifest imports. Live forced pagination returns all four projects with one per page. Strict fixture collection is Complete for both project and organization scopes.
Live-discovered corrections: The configured organization ID was actually a project ID; verified organization instance ID is 5e433049-1396-4a9d-80b2-33dc2f1e98af. Dashboard resolves it from connectionData; the rules pipeline configuration is corrected. Organization policy validation now normalizes whitespace so canonical API names are recognized without relaxing missing-field checks. Empty production service-connection check lists fail.
Remaining validation: Final combined offline/coverage run; full live integration suite (running); candidate pipeline execution, remote CI and final diff review. Main merge requires user approval.
