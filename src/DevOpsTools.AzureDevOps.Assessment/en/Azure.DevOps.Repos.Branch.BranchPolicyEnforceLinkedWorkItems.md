---
category: Microsoft Azure DevOps Repos
severity: Informational
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Repos.Branch.BranchPolicyEnforceLinkedWorkItems.md
---

# Azure.DevOps.Repos.Branch.BranchPolicyEnforceLinkedWorkItems

## SYNOPSIS

A policy should be configured to require linked work items for pull requests.

## DESCRIPTION

Require linked work items for pull requests to ensure that changes are associated with a work item. This helps to track changes and ensure that changes are associated with a work item and thus documented in some way.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Consider enabling the policy to require linked work items for pull requests.

## LINKS

- [Create a branch policy](https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops)
- [Branch policies](https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies-overview?view=azure-devops)
- [Azure DevOps Security best practices](https://docs.microsoft.com/en-us/azure/devops/user-guide/security-best-practices?view=azure-devops#repositories-and-branches)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
