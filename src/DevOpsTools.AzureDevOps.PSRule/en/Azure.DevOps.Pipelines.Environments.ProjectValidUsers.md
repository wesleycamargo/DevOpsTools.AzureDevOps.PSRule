---
category: Microsoft Azure DevOps Environments
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Environments.ProjectValidUsers.md
---

# Azure.DevOps.Pipelines.Environments.ProjectValidUsers

## SYNOPSIS

Environments should not be assigned directly to the Project Valid Users
group.

## DESCRIPTION

Environments should not be assigned directly to the Project Valid Users
group. This group is inherited by all users in the project and will grant
access to the environment to all users.

Mininum TokenType: `FineGrained`

## RECOMMENDATION

Remove the Project Valid Users group from the environment acl.

## LINKS

- [Azure DevOps Security best practices](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#scoped-permissions)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
