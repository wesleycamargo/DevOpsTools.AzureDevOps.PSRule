---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.LimitPRsFromForks.md
---

# Azure.DevOps.Organization.Pipelines.Settings.LimitPRsFromForks

## SYNOPSIS

Pull requests from forks should be limited in organization settings.

## DESCRIPTION

Limiting pull requests from forks in organization settings prevents unauthorized code execution in pipelines. This rule checks that the `forkProtectionEnabled` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Limit pull requests from forks" in Azure DevOps organization settings.

## LINKS

- [Protecting Branches in Forks](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/branches/fork-protection)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
