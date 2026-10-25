---
category: Microsoft Azure DevOps Repos
severity: Important
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/nl/Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes.md
---

# Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes

## SYNOPSIS

Het doel moet voldoen aan toepasselijk organisatiebeleid.

## DESCRIPTION

Deze controle volgt `assessmentPolicies['Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes']`. Elk expliciet beleid vereist een Reference. Zonder optioneel beleid is de controle niet van toepassing. Ontbrekend bewijs voor toepasselijk beleid resulteert in Unknown. PSRule geeft hiervoor None terug met -Outcome All; de beoordelingsprojectie onderscheidt deze uitkomsten. Zie de Engelstalige beleidsdocumentatie voor de exacte velden.

## RECOMMENDATION

Configureer en pas het beleid met bronverwijzing toe. Zie [beleidsconfiguratie](../../../docs/assessment/policies.md).

## ASSESSMENT

Onafhankelijk beoordelingsrisico: **Medium** (severity policy `1.0.0`). De bestaande helpclassificatie en het PSRule-niveau blijven compatibiliteitsmetadata; dit is een afzonderlijke risicoschaal.

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
