---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess.md
---

# Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess

## SYNOPSIS

Azure AD conditional access should be enforced.

## DESCRIPTION

Enforcing Azure AD conditional access enhances security by requiring additional authentication checks. This rule checks that the `policy.enforceAADConditionalAccess` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable Azure AD conditional access in Azure DevOps organization settings.

## LINKS

- [Conditional Access](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/overview)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
