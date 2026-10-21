---
category: Microsoft Azure DevOps Pipelines
severity: Critical
online version: https://github.com/cloudyspells/PSRule.Rules.AzureDevOps/blob/main/src/PSRule.Rules.AzureDevOps/nl/Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets.md
---

# Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets

## SYNOPSIS

Variabelegroepen mogen geen referenties blootstellen.

## DESCRIPTION

Afgeschermde Azure DevOps-geheimen (`isSecret: true`, `value: null`) zijn toegestaan zonder verplichte Key Vault. Niet-afgeschermde geheimen en waarden die overeenkomen met referentiepatronen falen. Patroonherkenning bewijst niet dat willekeurige tekst geen geheim bevat. Ontbrekende gegevens krijgen de beoordeling Unknown en worden niet door PSRule beoordeeld; dit is geen geslaagde controle.

Minimum TokenType: `ReadOnly`

## RECOMMENDATION

Gebruik afgeschermde geheime variabelen of Key Vault-verwijzingen. Roteer blootgestelde referenties en herstel ontbrekende verzamelrechten.

## LINKS

- [Secret variables](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-secret-variables)

## ASSESSMENT

Onafhankelijk beoordelingsrisico: **Medium** (severity policy `1.0.0`). De bestaande helpclassificatie en het PSRule-niveau blijven compatibiliteitsmetadata; dit is een afzonderlijke risicoschaal.

## ASSESSMENT

Independent assessment risk: **Critical** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
