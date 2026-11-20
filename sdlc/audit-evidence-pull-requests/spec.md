# Specification: Pull request review evidence collector

**Status:** Proposed; specification only.
**Scope:** One Azure DevOps Team Project; no existing PSRule rules or collectors modified.

## Goal
Collect completed pull request evidence suitable for an auditor inspecting the four-eyes review process. Do not mistake a currently listed reviewer vote for a historical approval at completion.

## Public interface
`Export-AzDevOpsPullRequestHistory -Project <name> [-StartTime <UTC>] [-EndTime <UTC>] [-OutputPath <directory> | -PassThru]`

- Reuse the current `Connect-AzDevOps` connection, credential handling, error sanitization, and existing module conventions.
- Default to a documented 90-day lookback; validate explicitly supplied UTC date range with inclusive start and exclusive end.
- Only collect repositories in the requested Team Project. Include *all* completed PRs in the window rather than picking one illustrative PR.
- Write `pull-request-history.ado.json` or return the same normalized objects from `-PassThru`, with no file writes in PassThru mode.

## Required evidence
For each PR, capture organization, project, repository name/ID, PR ID, title, link to Azure DevOps, source/target branch, created/completed timestamps, status, closed-by/completion actor if provided, and merge commit if provided.

Capture reviewer identities, reviewer types (individual/group), votes and available review events. Use the official PR and thread/history endpoints to capture chronologically ordered events with UTC timestamp, actor, event type, and source reference. Never fabricate events or infer an approval timestamp from the latest reviewer record.

Distinguish:
- `CurrentReviewerVotes`: current API snapshot, not proof of vote at merge time.
- `ApprovalHistoryStatus`: `Available` only when historical evidence is actually present; otherwise `Unavailable`.
- `FourEyesVerified`: do not set true merely because two reviewer names or votes appear; policy settings and historical enforcement are separate evidence.

Include collection timestamp, requested window and endpoint provenance.

## Collection, integration, failure behavior
1. Discover project repositories with existing helpers; retrieve completed PRs for every repository; follow all continuation/pagination mechanisms.
2. Filter completed timestamps in UTC and sort consistently. Retrieve reviewer details and available PR timeline/thread events, avoiding unnecessary comment bodies/PII.
3. Treat denied access, malformed responses, failed later pages and incomplete required history as `Partial`, `Unavailable` or `Failed` using the current collection-status semantics, never as successful empty data.
4. `Empty` requires a successful exhaustive query returning zero qualifying PRs. Distinguish absent optional history from entire collector failure.
5. Integrate the new project-scoped collector with `Invoke-AzDevOpsProjectExport` / `Export-AzDevOpsRuleData`, preserving existing collector outputs, rules and dashboards.

## Acceptance criteria
- [ ] Limits evidence strictly to the given Team Project and requested UTC window.
- [ ] Handles multiple repos, PR pages and timeline pages. A failure after page one is not `Completed`.
- [ ] Includes completed PRs only, excluding open and abandoned PRs.
- [ ] Shows current reviewer votes separately from timestamped historical events.
- [ ] Missing historical approval evidence is explicitly `Unavailable`, not inferred.
- [ ] Provides PR URLs for auditor inspection, valid JSON and equivalent PassThru output.
- [ ] Unit/Pester tests cover zero results, multiple pages, reviewer groups, changed votes, missing history, 401/403, 404, 429, 5xx and malformed results.
- [ ] Completeness diagnostics are accurate, sanitized, and do not leak authentication material.
- [ ] No modification to existing branch policy, repository ACL, group collectors or PSRule rules.

## Official references
- https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-requests/get-pull-requests?view=azure-devops-rest-7.1
- https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-reviewers/list?view=azure-devops-rest-7.1
- https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-threads/list?view=azure-devops-rest-7.1

## Existing implementation references
- `src/DevOpsTools.AzureDevOps.PSRule/Functions/DevOps.Repos.ps1`
- `src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psm1`
