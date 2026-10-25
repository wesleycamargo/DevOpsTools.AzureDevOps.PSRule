---
category: Repository
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.ServiceConnections.ProductionBranchLimit.md
---

# Azure.DevOps.ServiceConnections.ProductionBranchLimit

## SYNOPSIS

A production service connection should be limited in the branches it can be used
in.

## DESCRIPTION

This production-only rule uses the `IsProduction` name selector. Development resources are skipped. Name matching is a convention; configure names or suppressions to match your production inventory.

A production service connection should be limited in the branches it can be used
in. This ensures that the service connection is not used in a non-production
branch. This rule checks that the service connection is limited to a production
branch.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Consider limiting the service connection to a production branch.

## LINKS

- [Azure DevOps Service connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
