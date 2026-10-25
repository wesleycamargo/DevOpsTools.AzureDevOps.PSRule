---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.DisableClassicReleasePipelines.md
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableClassicReleasePipelines

## SYNOPSIS

Creation of classic release pipelines should be disabled in organization settings.

## DESCRIPTION

Disabling classic release pipelines in organization settings encourages the use of YAML pipelines, which are more secure and maintainable. This rule checks that the `disableClassicReleasePipelineCreation` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Disable creation of classic release pipelines" in Azure DevOps organization settings.

## LINKS

- [Security Overview](https://docs.microsoft.com/en-us/azure/devops/organizations/security/security-overview)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
