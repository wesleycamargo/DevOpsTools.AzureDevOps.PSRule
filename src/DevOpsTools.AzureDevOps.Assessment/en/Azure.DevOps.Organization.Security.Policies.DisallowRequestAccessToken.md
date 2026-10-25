---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Security.Policies.DisallowRequestAccessToken.md
---

# Azure.DevOps.Organization.Security.Policies.DisallowRequestAccessToken

## SYNOPSIS

Request access token should be disabled.

## DESCRIPTION

Disabling request access tokens prevents unauthorized access requests. This rule checks that the `policy.allowRequestAccessToken` setting is disabled in Azure DevOps organization security settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Disable request access token in Azure DevOps organization security settings.

## LINKS

- [Security Best Practices](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
