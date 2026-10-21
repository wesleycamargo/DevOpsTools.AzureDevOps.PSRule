---
category: Microsoft Azure DevOps Service Connections
severity: Severe
online version: https://github.com/cloudyspells/PSRule.Rules.AzureDevOps/blob/main/src/PSRule.Rules.AzureDevOps/nl/Azure.DevOps.ServiceConnections.ProductionCheckProtection.md
---

# Azure.DevOps.ServiceConnections.ProductionCheckProtection

## SYNOPSIS

Production resources should have a configured protection gate.

## DESCRIPTION

Een ingeschakelde geconfigureerde controle voldoet, ook als deze geautomatiseerd is. Menselijke goedkeuring is afzonderlijk beleid. Lege of uitgeschakelde controles falen; ontbrekende gegevens zijn Unknown. Dit beoordeelt de configuratie en bewijst geen succesvolle uitvoering van een deployment.

## RECOMMENDATION

Configure an enabled protection check and retain deployment execution evidence.

## ASSESSMENT

Onafhankelijk beoordelingsrisico: **High** (severity policy `1.0.0`). De bestaande helpclassificatie en het PSRule-niveau blijven compatibiliteitsmetadata; dit is een afzonderlijke risicoschaal.
