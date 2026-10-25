---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents.md
---

# Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents

## SYNOPSIS

Audit event logging should be enabled.

## DESCRIPTION

Enabling audit event logging ensures that all actions are tracked for security and compliance. This rule checks that the `policy.logAuditEvents` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable audit event logging in Azure DevOps organization settings.

## LINKS

- [Auditing](https://docs.microsoft.com/en-us/azure/devops/organizations/security/auditing)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
