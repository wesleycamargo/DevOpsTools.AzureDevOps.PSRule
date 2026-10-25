---
category: Microsoft Azure DevOps Service Connections
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/nl/Azure.DevOps.ServiceConnections.ProductionCheckProtection.md
---

# Azure.DevOps.ServiceConnections.ProductionCheckProtection

## SYNOPSIS

Production resources should have a configured protection gate.

## DESCRIPTION

Deze productieregel gebruikt de naamselector `IsProduction`. Ontwikkelbronnen worden overgeslagen. Naamherkenning is een conventie; stem namen of uitzonderingen af op uw productie-inventaris.

Een ingeschakelde geconfigureerde controle voldoet, ook als deze geautomatiseerd is. Menselijke goedkeuring is afzonderlijk beleid. Lege of uitgeschakelde controles falen; ontbrekende gegevens zijn Unknown. Dit beoordeelt de configuratie en bewijst geen succesvolle uitvoering van een deployment.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Configure an enabled protection check and retain deployment execution evidence.

## ASSESSMENT

Onafhankelijk beoordelingsrisico: **High** (severity policy `1.0.0`). De bestaande helpclassificatie en het PSRule-niveau blijven compatibiliteitsmetadata; dit is een afzonderlijke risicoschaal.

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
