# Audit evidence collectors — specification package

**Status:** Specifications only; no implementation or existing collectors/rules modified.

## Requested audit evidence
| Requirement | Implementation |
| --- | --- |
| Repository Policy (main branch review policy) | Reuse `Export-AzDevOpsReposAndBranchPolicies` |
| Access Permissions (Repo security, Contributors/Admins) | Reuse existing repository ACL and `Export-AzDevOpsGroups` data; validate effective/inherited permissions and membership before making claims |
| Code Audit Log (completed PR approvals/timeline) | [Pull request history specification](../audit-evidence-pull-requests/spec.md) |
| Management Audit Log (CSV plus UI screenshot) | [Organization audit-log specification](../audit-evidence-management-log/spec.md) |

## Deliberately excluded
No new PSRule rules, dashboard/HTML, screenshot automation, compliance assertions, or modification to existing collectors. Official API data supports JSON/CSV evidence; an actual Azure DevOps interface screenshot, if auditor-mandated, remains manual.

## Implementation order
1. Implement and test project-level Pull Request History collector.
2. Implement and test organization-level Audit Log collector and CSV export.
3. Register each in existing project/organization export orchestration respectively, test completeness reporting and regressions.
4. Keep support for direct invocation where only this evidence is requested; full `Export-AzDevOpsRuleData` continues to collect other targets.

## Global acceptance gate
Collectors are read-only, pagination-complete, project/organization scoped as documented, safe under missing permissions, JSON-valid, and covered by Pester tests. No partial exports are silently reported as complete.
