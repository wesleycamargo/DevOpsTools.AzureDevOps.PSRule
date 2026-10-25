---
category: Microsoft Azure DevOps Repos
severity: Important
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy.md
---

# Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy

## SYNOPSIS

A policy should be configured to define a merge strategy for pull requests.

## DESCRIPTION

The applicable policy must be enabled and blocking. Optional or disabled policy
configuration does not satisfy this control. Branch policy scope supports exact
and prefix branch matches and policies covering all repositories.

Define a merge strategy for pull requests to ensure that changes are merged in a consistent way. This helps to ensure that changes are merged in a consistent way and thus reduces the risk of merge conflicts.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Consider enabling the policy to define a merge strategy for pull requests.

## LINKS

- [Create a branch policy](https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops)
- [Branch policies](https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies-overview?view=azure-devops)
- [Azure DevOps Security best practices](https://docs.microsoft.com/en-us/azure/devops/user-guide/security-best-practices?view=azure-devops#repositories-and-branches)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
