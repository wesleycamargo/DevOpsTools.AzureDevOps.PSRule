---
category: Repository
severity: Severe
online version: https://github.com/cloudyspells/PSRule.Rules.AzureDevOps/blob/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Pipelines.Environments.ProductionBranchLimit.md
---

# Azure.DevOps.Pipelines.Environments.ProductionBranchLimit

## SYNOPSIS

A production environment should be limited to the branches it can be used in.

## DESCRIPTION

This production-only rule uses the `IsProduction` name selector. Development resources are skipped. Name matching is a convention; configure names or suppressions to match your production inventory.

A production environment should be limited to the branches it can be used in. This ensures
the environment is not used in a non-production branch. This rule checks if the
environment is limited to a production branch.

Mininum TokenType: `FineGrained`

## RECOMMENDATION

Consider limiting the environment to a production branch.

## LINKS

- [Azure DevOps Pipelines Environments](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
