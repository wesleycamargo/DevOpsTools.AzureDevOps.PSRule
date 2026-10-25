---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.EnableTaskLockdown.md
---

# Azure.DevOps.Organization.Pipelines.Settings.EnableTaskLockdown

## SYNOPSIS

Task lockdown feature should be enabled in organization settings.

## DESCRIPTION

Enabling the task lockdown feature in organization settings restricts the use of unauthorized tasks, enhancing pipeline security. This rule checks that the `isTaskLockdownFeatureEnabled` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Task lockdown feature" in Azure DevOps organization settings.

## LINKS

- [Secure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines)

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
