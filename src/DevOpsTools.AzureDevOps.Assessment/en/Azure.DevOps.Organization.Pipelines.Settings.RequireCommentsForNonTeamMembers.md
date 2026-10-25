---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamMembers.md
---

# Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamMembers

## SYNOPSIS

Comments should be required for non-team members in organization settings.

## DESCRIPTION

Requiring comments for non-team members in organization settings ensures that external contributors provide context for their changes. This rule checks that the `requireCommentsForNonTeamMembersOnly` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Require comments for non-team members" in Azure DevOps organization settings.

## LINKS

- [Require Reviewers](https://learn.microsoft.com/en-us/azure/devops/organizations/security/require-reviewers)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
