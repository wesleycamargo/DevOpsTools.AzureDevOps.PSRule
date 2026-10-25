---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForPullRequest.md
---

# Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForPullRequest

## SYNOPSIS

Comments should be required for pull requests in organization settings.

## DESCRIPTION

Requiring comments for pull requests in organization settings ensures that changes are reviewed and documented, improving code quality and traceability. This rule checks that the `isCommentRequiredForPullRequest` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Require comments for pull requests" in Azure DevOps organization settings.

## LINKS

- [Require Reviewers](https://learn.microsoft.com/en-us/azure/devops/organizations/security/require-reviewers)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
