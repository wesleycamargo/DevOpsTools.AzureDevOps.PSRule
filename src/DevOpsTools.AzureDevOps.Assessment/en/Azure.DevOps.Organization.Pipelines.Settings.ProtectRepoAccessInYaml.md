---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.ProtectRepoAccessInYaml.md
---

# Azure.DevOps.Organization.Pipelines.Settings.ProtectRepoAccessInYaml

## SYNOPSIS

Access to repositories in YAML pipelines should be protected in organization settings.

## DESCRIPTION

Protecting access to repositories in YAML pipelines in organization settings ensures that only authorized repositories are used. This rule checks that the `enforceReferencedRepoScopedToken` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Protect access to repositories in YAML pipelines" in Azure DevOps organization settings.

## LINKS

- [Security Overview](https://docs.microsoft.com/en-us/azure/devops/organizations/security/security-overview)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
