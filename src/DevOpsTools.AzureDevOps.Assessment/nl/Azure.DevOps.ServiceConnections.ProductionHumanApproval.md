---
category: Microsoft Azure DevOps Service Connections
severity: Severe
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/nl/Azure.DevOps.ServiceConnections.ProductionHumanApproval.md
---

# Azure.DevOps.ServiceConnections.ProductionHumanApproval

## SYNOPSIS

Het doel moet voldoen aan toepasselijk organisatiebeleid.

## DESCRIPTION

Deze productieregel gebruikt de naamselector `IsProduction`. Ontwikkelbronnen worden overgeslagen. Naamherkenning is een conventie; stem namen of uitzonderingen af op uw productie-inventaris.

Deze controle volgt `assessmentPolicies['Azure.DevOps.ServiceConnections.ProductionHumanApproval']`. Elk expliciet beleid vereist een Reference. Zonder optioneel beleid is de controle niet van toepassing. Ontbrekend bewijs voor toepasselijk beleid resulteert in Unknown. PSRule geeft hiervoor None terug met -Outcome All; de beoordelingsprojectie onderscheidt deze uitkomsten. Zie de Engelstalige beleidsdocumentatie voor de exacte velden.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Configureer en pas het beleid met bronverwijzing toe. Zie [beleidsconfiguratie](../../../docs/assessment/policies.md).

## ASSESSMENT

Onafhankelijk beoordelingsrisico: **High** (severity policy `1.0.0`). De bestaande helpclassificatie en het PSRule-niveau blijven compatibiliteitsmetadata; dit is een afzonderlijke risicoschaal.

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
