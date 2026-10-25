---
category: Microsoft Azure DevOps Pipelines
severity: Severe
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/nl/Azure.DevOps.Pipelines.Releases.Definition.SelfApproval.md
---

# Azure.DevOps.Pipelines.Releases.Definition.SelfApproval

## SYNOPSIS

Een release stage die is beperkt tot productie mag geen zelfgoedkeuring toestaan.

## DESCRIPTION

Een release stage die is beperkt tot productie mag geen zelfgoedkeuring toestaan. Deze
regel controleert of een release stage die is beperkt tot productie zelfgoedkeuring heeft ingeschakeld.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Overweeg om zelfgoedkeuring voor de omgeving uit te schakelen.

## LINKS

- [Release Pipelines](https://docs.microsoft.com/nl-nl/azure/devops/pipelines/release/?view=azure-devops)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
