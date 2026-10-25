---
category: Microsoft Azure DevOps Repos
severity: Severe
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild.md
---

# Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild

## SYNOPSIS

The branch policy for the default branch should be configured to require a
build or CI pipeline to pass before changes can be merged into the default
branch.

## DESCRIPTION

The applicable policy must be enabled and blocking. Optional or disabled policy
configuration does not satisfy this control. Branch policy scope supports exact
and prefix branch matches and policies covering all repositories.

The branch policy should be configured to require a build or CI pipeline to pass
before changes can be merged into the default branch. This ensures that changes
are validated before being merged into the default branch. This rule does not
validate that the build or CI pipeline is configured correctly. It only validates
that a build or CI pipeline is configured.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Consider enabling the branch policy to require a build or CI pipeline to pass

## LINKS

- [Create a branch policy](https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops)
- [Branch policies](https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies-overview?view=azure-devops)
- [Azure DevOps Security best practices](https://docs.microsoft.com/en-us/azure/devops/user-guide/security-best-practices?view=azure-devops#policies)

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
