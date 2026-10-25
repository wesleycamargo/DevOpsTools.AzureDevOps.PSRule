---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Security.Policies.EnableArtifactsProtection.md
---

# Azure.DevOps.Organization.Security.Policies.EnableArtifactsProtection

## SYNOPSIS

External package protection for artifacts should be enabled.

## DESCRIPTION

Enabling external package protection ensures secure artifact management. This rule checks that the `policy.artifactsExternalPackageProtectionToken` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable external package protection in Azure DevOps organization settings.

## LINKS

- [Artifacts Security](https://docs.microsoft.com/en-us/azure/devops/organizations/security/artifacts-security)

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
