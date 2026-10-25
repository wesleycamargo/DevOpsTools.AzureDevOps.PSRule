---
category: Microsoft Azure DevOps Variable Groups
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Tasks.VariableGroup.InheritedPermissions.md
---

# Azure.DevOps.Tasks.VariableGroup.InheritedPermissions

## SYNOPSIS

Effective sensitive permissions must be authorized by organizational policy.

## DESCRIPTION

The historical rule ID is retained, but inheritance alone is no longer a failure. The rule evaluates the ordered ACL path, nested group membership, explicit allow and deny, and administrative bypass in `PermissionEvidence`. Configure `effectivePermissionPolicies` for target type `Azure.DevOps.Tasks.VariableGroup` with a policy reference, security namespace, sensitive permission mask, and allowed descriptor-to-mask map. Missing policy, ACL ancestry, identity resolution, or administrator evidence is Unknown in assessment output and not evaluated by PSRule. It never becomes a pass. Read-only inherited access is allowed; unauthorized sensitive rights fail.

## RECOMMENDATION

Collect complete permission evidence and restrict unauthorized privileges. Keep legitimate least-privilege inheritance. See [permission evidence](../../../docs/assessment/permission-evidence.md) for collection and policy configuration.

## LINKS

- [Permissions and inheritance](https://learn.microsoft.com/en-us/azure/devops/organizations/security/about-permissions)

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
