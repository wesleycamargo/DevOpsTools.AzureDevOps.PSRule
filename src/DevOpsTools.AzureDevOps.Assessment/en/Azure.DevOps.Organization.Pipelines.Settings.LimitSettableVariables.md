---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.LimitSettableVariables.md
---

# Azure.DevOps.Organization.Pipelines.Settings.LimitSettableVariables

## SYNOPSIS

Variables settable at queue time should be limited in organization settings.

## DESCRIPTION

Limiting variables that can be set at queue time in organization settings prevents unauthorized changes to pipeline behavior. This rule checks that the `enforceSettableVar` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Limit variables that can be set at queue time" in Azure DevOps organization settings.

## LINKS

- [Security Overview](https://docs.microsoft.com/en-us/azure/devops/organizations/security/security-overview)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
