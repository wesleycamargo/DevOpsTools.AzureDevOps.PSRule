---
category: Repository
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.ServiceConnections.ProductionBranchLimit.md
---

# Azure.DevOps.ServiceConnections.ProductionBranchLimit

## SYNOPSIS

A production service connection should be limited in the branches it can be used
in.

## DESCRIPTION

Production scope can be explicitly configured by exact ObjectName, overriding the name fallback. Name matching recognizes delimited production/prod/prd/live only (not main/master).

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

## EVIDENCE (rule-set 2026.11.06.1)

Explicit productionTargets mappings select exact environment or service connection ObjectName values. An active Branch control must restrict allowed branches; a wildcard or disabled check does not prove protection. Checks configured in Azure DevOps do not prove execution.
