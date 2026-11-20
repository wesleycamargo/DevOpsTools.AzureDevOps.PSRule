# Specification: Management audit-log evidence collector

**Status:** Proposed; specification only.
**Scope:** Azure DevOps organization audit events, with conservative optional Team Project attribution.

## Goal
Retrieve actual management audit events and export JSON/CSV for auditors. Reuse but do **not** modify the existing rule `Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents` (ADO-OSP-007): it checks whether logging is enabled but does not retrieve audit history.

## Public interface
`Export-AzDevOpsAuditLog -Organization <name> [-Project <name>] [-StartTime <UTC>] [-EndTime <UTC>] [-OutputPath <directory> | -PassThru]`

- Reuse `Connect-AzDevOps`; the supplied organization must match the connected organization.
- Default to the preceding 30 days; allow explicit validated UTC inclusive-start/exclusive-end window subject to retention.
- When OutputPath is supplied, produce `organization-audit-log.ado.json` and `organization-audit-log.csv`. PassThru returns normalized objects without file writes.
- Use the official Audit Log REST endpoint at `https://auditservice.dev.azure.com/{organization}/_apis/audit/auditlog` with a supported API version, time range and continuation tokens. Verify the endpoint/version and response shape during implementation; never use undocumented organization-policy endpoints to fetch events.

## Evidence contract
Preserve available audit event ID, timestamp UTC, actor identity, action ID/category, organization scope, structured project association if present, correlation/activity ID, detail/message (with safe redaction where applicable), collection timestamp, queried range and source API provenance.

- Follow every continuation page and detect repeated continuation tokens. An incomplete page sequence cannot be reported as complete.
- Export CSV from exactly the same normalized event set as JSON; stable headers, UTF-8, escaping for commas/quotes/newlines and explicit UTC dates.
- Keep identifiers as strings, never transform them into CSV numbers.

## Project filtering
The Audit Log is **organization-scoped**. `-Project` must not imply an independent project audit feed:
1. Resolve the project identifier/name.
2. Classify events as `Matched`, `NotMatched` or `Unattributed` using authoritative structured project scope/IDs, not substring matching in free-text messages.
3. The project-filtered export includes only confidently matched events, and reports counts of unattributed events plus a coverage warning.
4. Zero matched events must never be presented as proof that no management actions occurred.
5. Without `-Project`, export the entire requested organization window.
6. Register the new organization collector once per `Export-AzDevOpsRuleData` invocation; do not repeat it per project. Keep optional project-filtered collection accessible through direct invocation without refactoring the existing organization flow.

## Completeness, permissions and safety
- Use the documented audit-log permission model, and classify permission denied, unavailable endpoint, retention gaps, invalid data and failed later pages accurately.
- A successful full query with no events may be `Empty`; missing access, disabled logging, out-of-retention periods and partial retrieval must not be classified as successful emptiness.
- Use existing completeness status contract and error sanitization. Do not log credentials or sensitive raw API responses.
- Do not claim that having audit logging currently enabled proves historical logging coverage.

## Acceptance criteria
- [ ] Retrieves actual events from an official organization audit REST interface using UTC time bounds.
- [ ] Paginates to exhaustion; a failed later page or repeating token cannot yield `Completed`.
- [ ] JSON/CSV contain equivalent records and metadata; CSV handles commas, quotes and multiline messages.
- [ ] PassThru returns normalized objects without creating files.
- [ ] Project filtering uses structured attribution; reports unattributed counts; does not silently discard them without a warning.
- [ ] No-project request exports organization-scoped events once in the full assessment flow.
- [ ] Tests cover empty results, pagination, malformed data, 401/403, 404, 429/5xx, expired retention, unsupported attribution and data sanitization.
- [ ] Existing ADO-OSP-007 check and other organization collectors remain unchanged.

## Official references
- https://learn.microsoft.com/en-us/rest/api/azure/devops/audit/audit-log/query?view=azure-devops-rest-7.1
- https://learn.microsoft.com/en-us/azure/devops/organizations/audit/azure-devops-auditing?view=azure-devops
- Existing code: `src/DevOpsTools.AzureDevOps.PSRule/Functions/DevOps.Organization.SecurityPolicies.ps1`.
