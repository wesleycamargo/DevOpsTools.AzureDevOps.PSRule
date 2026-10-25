---
category: Microsoft Azure DevOps Pipelines
severity: Critical
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/nl/Azure.DevOps.Pipelines.Releases.Definition.NoPlainTextSecrets.md
---

# Azure.DevOps.Pipelines.Releases.Definition.NoPlainTextSecrets

## SYNOPSIS

Release pipelines zouden geen geheimen in platte tekst moeten bevatten.

## DESCRIPTION

Detectie is heuristisch en beperkt tot geëxporteerde waarden. Herkenbare verbindingspatronen en Azure DevOps PAT's van 84 tekens met een vaste signatuur worden gecontroleerd. Willekeurige waarden van 32/40 tekens en oude PAT's zonder signatuur zijn niet betrouwbaar aan hun lengte te herkennen. Een geslaagde controle bewijst niet dat geheimen ontbreken. Foutmeldingen bevatten geen gevonden waarden.

Release pipeline-variabelen mogen geen geheimen in platte tekst bevatten. Geheimen moeten
worden opgeslagen in Azure Key Vault en worden gerefereerd in de variabele groep. Dit zal
voorkomen dat het geheim wordt blootgesteld in de build logs. Als het geheim in platte
tekst wordt opgeslagen, wordt het blootgesteld in de build logs.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Overweeg om geheimen op te slaan in Azure Key Vault en ze te refereren in de variabele
groep.

## LINKS

- [Azure DevOps Security best practices - Tasks](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#tasks)

## ASSESSMENT

Independent assessment risk: **Critical** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
