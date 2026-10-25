---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.DisableStageChooser.md
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableStageChooser

## SYNOPSIS

Stage chooser should be disabled in organization settings.

## DESCRIPTION

Disabling the stage chooser in organization settings prevents users from manually selecting stages during pipeline runs, reducing the risk of unintended deployments. This rule checks that the `disableStageChooser` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Disable stage chooser" in Azure DevOps organization settings.

## LINKS

- [Secure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
