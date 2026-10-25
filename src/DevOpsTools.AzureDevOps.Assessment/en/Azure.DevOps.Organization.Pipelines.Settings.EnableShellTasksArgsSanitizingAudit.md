---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.EnableShellTasksArgsSanitizingAudit.md
---

# Azure.DevOps.Organization.Pipelines.Settings.EnableShellTasksArgsSanitizingAudit

## SYNOPSIS

Auditing of shell task arguments sanitization should be enabled in organization settings.

## DESCRIPTION

Enabling auditing of shell task arguments sanitization in organization settings ensures that sanitization activities are logged for security monitoring. This rule checks that the `enableShellTasksArgsSanitizingAudit` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Audit shell task arguments sanitization" in Azure DevOps organization settings.

## LINKS

- [Secure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
