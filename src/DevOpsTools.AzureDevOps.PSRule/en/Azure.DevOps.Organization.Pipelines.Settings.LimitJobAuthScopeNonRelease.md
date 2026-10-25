---
category: Microsoft Azure DevOps Organization
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeNonRelease.md
---

# Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeNonRelease

## SYNOPSIS

Job authorization scope for non-release pipelines should be limited in organization settings.

## DESCRIPTION

Limiting job authorization scope for non-release pipelines in organization settings reduces the risk of unauthorized access to resources. This rule checks that the `enforceJobAuthScope` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Limit job authorization scope for non-release pipelines" in Azure DevOps organization settings.

## LINKS

- [Security Overview](https://docs.microsoft.com/en-us/azure/devops/organizations/security/security-overview)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
