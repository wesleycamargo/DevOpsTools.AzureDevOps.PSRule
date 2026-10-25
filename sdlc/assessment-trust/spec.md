# Specification: Trustworthy Azure DevOps assessments

## Authorization
Implements the user-approved review scope. Routine technical decisions are delegated; main merges require approval.

## Requirements
1. Mandatory branch controls require a matching enabled, blocking policy with valid settings. Scope matching evaluates each scope atomically, including exact/prefix branches and all repositories.
2. Project and pipeline lists exhaust continuation tokens. Later-page failure cannot yield complete collection. Audit other list endpoints for the same omission.
3. File evidence distinguishes confirmed absence/empty repositories from authorization, throttling and network errors.
4. Organization exports collect organization targets once, including when no projects exist, and report organization and project completeness separately. Single-project exports retain existing organization targets. Obtain fresh headers immediately before organization collection.
5. Managed identity expiry uses UTC consistently. Failed connection verification preserves the previous working connection.
6. Production-only rules skip development resources using the established selector. Secret detection must reject documented credential formats without classifying arbitrary fixed-length checksums as secrets, and must not expose matched values.
7. Dashboard assessment uses a fresh directory, strict collection and a report outside target inputs. Incomplete collection prevents evaluation, dashboard generation and ingestion; completeness diagnostics remain artifacts.
8. CI covers all relevant source, manifest, test, pipeline and workflow changes; shares pinned local configuration; explicitly fails on test failures; retains diagnostics on failure. Remove unused upstream SonarCloud configuration; the user confirms there is no SonarCloud integration.
9. Gallery publishing uses explicit validated manual version/tag inputs, verifies tag/manifest agreement, tests and builds before publishing. No publication is performed merely to validate this change.
10. Preserve advisory security findings and live integration tests. Candidate validation must not merge or silently change production pipelines to unapproved main code.

## Acceptance
Offline regressions exercise enforcement flags, scope combinations, multiple pages and later-page failures, file error categories, zero/multiple projects, token refresh/UTC, applicability, checksum false positives, strict dashboard failure and CI/release contracts. Run available live checks against existing fixtures and record external blockers without changing expectations to hide failures.
