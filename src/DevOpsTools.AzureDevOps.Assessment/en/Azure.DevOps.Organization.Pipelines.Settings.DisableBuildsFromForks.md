---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.DisableBuildsFromForks.md
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableBuildsFromForks

## SYNOPSIS

Builds from forks should be disabled in organization settings.

## DESCRIPTION

Disabling builds from forks in organization settings reduces the risk of executing untrusted code. This rule checks that the `buildsEnabledForForks` setting is disabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Disable "Allow builds from forks" in Azure DevOps organization settings.

## LINKS

- [Protecting Branches in Forks](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/branches/fork-protection)

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
