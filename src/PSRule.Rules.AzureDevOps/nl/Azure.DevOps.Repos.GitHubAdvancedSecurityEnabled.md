---
category: Microsoft Azure DevOps Repos
severity: Important
online version: https://github.com/cloudyspells/PSRule.Rules.AzureDevOps/blob/main/src/PSRule.Rules.AzureDevOps/nl/Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled.md
---

# Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled

## SYNOPSIS

Het doel moet voldoen aan toepasselijk organisatiebeleid.

## DESCRIPTION

Deze controle volgt `assessmentPolicies['Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled']`. Elk expliciet beleid vereist een Reference. Zonder optioneel beleid is de controle niet van toepassing. Ontbrekend bewijs voor toepasselijk beleid resulteert in Unknown. PSRule geeft hiervoor None terug met -Outcome All; de beoordelingsprojectie onderscheidt deze uitkomsten. Zie de Engelstalige beleidsdocumentatie voor de exacte velden.

## RECOMMENDATION

Configureer en pas het beleid met bronverwijzing toe. Zie [beleidsconfiguratie](../../../docs/assessment/policies.md).

## ASSESSMENT

Onafhankelijk beoordelingsrisico: **Medium** (severity policy `1.0.0`). De bestaande helpclassificatie en het PSRule-niveau blijven compatibiliteitsmetadata; dit is een afzonderlijke risicoschaal.
