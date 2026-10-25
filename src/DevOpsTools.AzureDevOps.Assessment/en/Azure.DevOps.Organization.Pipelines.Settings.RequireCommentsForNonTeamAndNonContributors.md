---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamAndNonContributors.md
---

# Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamAndNonContributors

## SYNOPSIS

Comments should be required for non-team members and non-contributors in organization settings.

## DESCRIPTION

Requiring comments for non-team members and non-contributors in organization settings ensures that external changes are well-documented. This rule checks that the `requireCommentsForNonTeamMemberAndNonContributors` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Require comments for non-team members and non-contributors" in Azure DevOps organization settings.

## LINKS

- [Require Reviewers](https://learn.microsoft.com/en-us/azure/devops/organizations/security/require-reviewers)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
