---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.RestrictPipelinePoliciesPermission.md
---

# Azure.DevOps.Organization.Pipelines.Settings.RestrictPipelinePoliciesPermission

## SYNOPSIS

Pipeline policies permission should be restricted in organization settings.

## DESCRIPTION

Restricting pipeline policies permission in organization settings ensures that only authorized users can modify pipeline configurations. This rule checks that the `hasManagePipelinePoliciesPermission` setting is disabled for non-administrators in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Disable "Manage pipeline policies permission" for non-administrators in Azure DevOps organization settings.

## LINKS

- [Permissions](https://learn.microsoft.com/en-us/azure/devops/organizations/security/permissions)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
