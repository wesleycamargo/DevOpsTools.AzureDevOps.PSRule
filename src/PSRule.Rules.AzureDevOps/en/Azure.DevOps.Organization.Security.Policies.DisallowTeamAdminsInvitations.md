---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Security.Policies.DisallowTeamAdminsInvitations.md  
---

# Azure.DevOps.Organization.Security.Policies.DisallowTeamAdminsInvitations

## SYNOPSIS

Team admins should not manage invitations.

## DESCRIPTION

Preventing team admins from managing invitations centralizes user management. This rule checks that the `policy.allowTeamAdminsInvitationsAccessToken` setting is disabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Disable team admin invitation management in Azure DevOps organization settings.

## LINKS

- [Permissions](https://learn.microsoft.com/en-us/azure/devops/organizations/security/permissions)

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
