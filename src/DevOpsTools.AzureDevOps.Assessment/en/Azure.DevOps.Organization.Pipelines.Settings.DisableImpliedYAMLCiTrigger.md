---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.DisableImpliedYAMLCiTrigger.md
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableImpliedYAMLCiTrigger

## SYNOPSIS

Implied YAML CI triggers should be disabled in organization settings.

## DESCRIPTION

Disabling implied YAML CI triggers in organization settings prevents automatic pipeline runs for unverified changes, improving security. This rule checks that the `disableImpliedYAMLCiTrigger` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Disable implied YAML CI triggers" in Azure DevOps organization settings.

## LINKS

- [Secure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
