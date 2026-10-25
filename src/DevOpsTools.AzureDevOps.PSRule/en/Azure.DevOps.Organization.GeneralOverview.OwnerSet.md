---
category: Microsoft Azure DevOps Organization
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.GeneralOverview.OwnerSet.md
---

# Azure.DevOps.Organization.GeneralOverview.OwnerSet

## SYNOPSIS

Organization owner should be set.

## DESCRIPTION

Setting the organization owner ensures accountability and proper management of the organization. This rule checks that the `owner` setting is configured in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Set an owner in Azure DevOps organization settings.

## LINKS

- [Organization Overview](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/organization-overview)

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
