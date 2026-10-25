# Effective permission evidence

The six `InheritedPermissions` IDs retain their identity but now evaluate effective access. Their precondition excludes unavailable evidence. `Get-AzDevOpsEffectivePermissionAssessment` returns `Unknown` with a reason code, `Pass`, or `Fail`; PSRule represents unknown as `None`/not evaluated when invoked with `-Outcome All`. Do not count `None` as a pass or silently remove it from coverage reporting.

## Collect evidence

`Get-AzDevOpsPermissionEvidence` uses the connected organization and read-only Security Namespaces, Access Control Lists, and Identities APIs. It queries ancestors from root to target, resolves direct members recursively, and collects only descriptors and permissions needed for assessment. API errors, malformed responses, unresolved groups, token translators, or unsupported namespace structures leave evidence partial. Existing exports without this evidence remain Unknown.

Administrative bypass cannot be derived from ordinary ACL allow/deny bits. Supply a reviewed descriptor-to-mask map of the platform's actual bypass privileges and its evidence reference. An explicitly reviewed empty map means no bypass applies. This map is observed access, not authorization. The separate `Allowed` policy map decides which access is acceptable. Never infer the administrator inventory from an allow list.

```powershell
# Values below are synthetic; derive namespace action bits and identities from the organization.
$namespace = '33344d9c-fc72-4d6f-aba5-fa317101a7e9'
$evidence = Get-AzDevOpsPermissionEvidence -NamespaceId $namespace -Token 'project/pipeline' `
    -AdministrativeBypass $reviewedBypassMap -AdministrativeEvidenceReference 'access-review-2026-10' `
    -AdditionalDescriptors @($approvedPrincipalMap.Keys)
$pipeline | Add-Member -NotePropertyName PermissionEvidence -NotePropertyValue $evidence -Force
$policy = @{
    Reference = 'pipeline-access-policy-v1'
    NamespaceId = $namespace
    SensitiveMask = $reviewedSensitiveMask
    Allowed = $approvedPrincipalMap
}
$option = New-PSRuleOption -Configuration @{
    effectivePermissionPolicies = @{ 'Azure.DevOps.Pipeline' = $policy }
}
$pipeline | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name '*.InheritedPermissions' -Option $option -Outcome All
```

Use the exact target type from `source-inventory.json`; each type has its own policy. Sensitive masks must cover the relevant edit, queue/run, administer, deployment, check modification, service-connection use/authorization, or repository bypass/force-push/manage permissions from that namespace. Do not reuse numeric bits between namespaces. Only referenced organizational policy can decide which principals are authorized.

## Resolution and completeness

The evidence schema is version 1. `Acls` is ordered root-to-leaf and its final token must equal `Token`. Disabling inheritance clears ancestor grants. A child explicit permission overrides the inherited state for that identity. Across a user's group closure, deny overrides allow; observed administrative bypass is applied separately. Policy authorization can name users or resolved groups. Unresolved identities or policy descriptors return Unknown. Membership cycles terminate without losing grants.

`ScopeComplete`, `IdentitiesComplete`, and `AdministratorsComplete` must all be true, and `Status` must be `Complete`. These fields are collection assertions, not switches to make an assessment pass. Hand-authored fixtures are appropriate only in tests; production data must retain collection and review provenance.

## Sources

- [ACL query and extended information](https://learn.microsoft.com/en-us/rest/api/azure/devops/security/access-control-lists/query?view=azure-devops-rest-7.1)
- [Identity membership query](https://learn.microsoft.com/en-us/rest/api/azure/devops/ims/identities/read-identities?view=azure-devops-rest-7.1)
- [Security namespace metadata](https://learn.microsoft.com/en-us/rest/api/azure/devops/security/security-namespaces/query?view=azure-devops-rest-7.1)
- [Permission and inheritance semantics](https://learn.microsoft.com/en-us/azure/devops/organizations/security/about-permissions)
