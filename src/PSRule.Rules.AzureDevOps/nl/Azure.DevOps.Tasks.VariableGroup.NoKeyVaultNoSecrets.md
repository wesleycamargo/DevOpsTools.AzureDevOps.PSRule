---
category: Microsoft Azure DevOps Distributed Task
severity: Critical
online version: https://github.com/cloudyspells/PSRule.Rules.AzureDevOps/blob/main/src/PSRule.Rules.AzureDevOps/nl/Azure.DevOps.Tasks.VariableGroup.NoKeyVaultNoSecrets.md
---

# Azure.DevOps.Tasks.VariableGroup.NoKeyVaultNoSecrets

## SYNOPSIS

Variabelegroepen mogen geen referenties blootstellen.

## DESCRIPTION

Deze regel-ID is verouderd en blijft beschikbaar als alias voor `Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets`. Beide diagnostieken behoren tot dezelfde risicogroep. Afgeschermde Azure DevOps-geheimen (`isSecret: true`, `value: null`) zijn toegestaan zonder verplichte Key Vault. Niet-afgeschermde geheimen en waarden die overeenkomen met referentiepatronen falen. Patroonherkenning bewijst niet dat willekeurige tekst geen geheim bevat. Ontbrekende gegevens krijgen de beoordeling Unknown en worden niet door PSRule beoordeeld; dit is geen geslaagde controle.

Minimum TokenType: `ReadOnly`

## RECOMMENDATION

Gebruik afgeschermde geheime variabelen of Key Vault-verwijzingen. Roteer blootgestelde referenties en herstel ontbrekende verzamelrechten.

## LINKS

- [Secret variables](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-secret-variables)

## ASSESSMENT

Onafhankelijk beoordelingsrisico: **Medium** (severity policy `1.0.0`). De bestaande helpclassificatie en het PSRule-niveau blijven compatibiliteitsmetadata; dit is een afzonderlijke risicoschaal.
