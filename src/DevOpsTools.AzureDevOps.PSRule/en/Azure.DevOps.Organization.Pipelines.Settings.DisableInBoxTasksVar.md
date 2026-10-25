---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.DisableInBoxTasksVar.md
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableInBoxTasksVar

## SYNOPSIS

In-box task variables should be disabled in organization settings.

## DESCRIPTION

Disabling in-box task variables in organization settings prevents the use of potentially outdated or insecure tasks, encouraging the use of maintained tasks. This rule checks that the `disableInBoxTasksVar` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Disable in-box task variables" in Azure DevOps organization settings.

## LINKS

- [Secure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
