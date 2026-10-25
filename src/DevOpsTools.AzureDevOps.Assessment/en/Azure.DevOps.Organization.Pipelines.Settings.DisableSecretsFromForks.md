---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.DisableSecretsFromForks.md
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableSecretsFromForks

## SYNOPSIS

Access to secrets from forks should be disabled in organization settings.

## DESCRIPTION

Disabling access to secrets from forks in organization settings prevents untrusted code from accessing sensitive information. This rule checks that the `enforceNoAccessToSecretsFromForks` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Disable access to secrets from forks" in Azure DevOps organization settings.

## LINKS

- [Protecting Branches in Forks](https://learn.microsoft.com/en-us/azure/devops/pipelines/repos/branches/fork-protection)

## ASSESSMENT

Independent assessment risk: **Critical** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
