---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.SanitizeShellTaskArguments.md
---

# Azure.DevOps.Organization.Pipelines.Settings.SanitizeShellTaskArguments

## SYNOPSIS

Shell task arguments should be sanitized in organization settings.

## DESCRIPTION

Sanitizing shell task arguments in organization settings prevents injection attacks in pipeline scripts. This rule checks that the `enableShellTasksArgsSanitizing` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Sanitize shell task arguments" in Azure DevOps organization settings.

## LINKS

- [Security Overview](https://docs.microsoft.com/en-us/azure/devops/organizations/security/security-overview)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
