---
category: Repository
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/nl/Azure.DevOps.Pipelines.Environments.ProductionBranchLimit.md
---

# Azure.DevOps.Pipelines.Environments.ProductionBranchLimit

## SYNOPSIS

Een productie environment moet beperkt zijn in de branches waarin deze kan worden gebruikt.

## DESCRIPTION

Deze productieregel gebruikt de naamselector `IsProduction`. Ontwikkelbronnen worden overgeslagen. Naamherkenning is een conventie; stem namen of uitzonderingen af op uw productie-inventaris.

Een productie environment moet beperkt zijn in de branches waarin deze kan worden gebruikt. Dit zorgt ervoor dat de omgeving niet wordt gebruikt in een
niet-productiebranch. Deze regel controleert of de environment is beperkt tot een
productiebranch.

Mininum TokenType: `FineGrained`

## RECOMMENDATION

Overweeg om de environment te beperken tot een productiebranch.

## LINKS

- [Azure DevOps Pipelines Environments](https://docs.microsoft.com/nl-nl/azure/devops/pipelines/process/environments)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
