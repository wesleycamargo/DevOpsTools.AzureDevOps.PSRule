---
category: Microsoft Azure DevOps Repos
severity: Important
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution.md
---

# Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution

## SYNOPSIS

A policy should be configured on the default branch to require comments for
pull requests to be resolved.

## DESCRIPTION

The applicable policy must be enabled and blocking. Optional or disabled policy
configuration does not satisfy this control. Branch policy scope supports exact
and prefix branch matches and policies covering all repositories.

Require comments for pull requests to be resolved to ensure that all comments are addressed. This helps to ensure that all comments are addressed and improves the quality of the pull request.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Consider enabling the policy to require comments for pull requests to be resolved.

## LINKS

- [Create a branch policy](https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops)
- [Branch policies](https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies-overview?view=azure-devops)
- [Azure DevOps Security best practices](https://docs.microsoft.com/en-us/azure/devops/user-guide/security-best-practices?view=azure-devops#repositories-and-branches)

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
