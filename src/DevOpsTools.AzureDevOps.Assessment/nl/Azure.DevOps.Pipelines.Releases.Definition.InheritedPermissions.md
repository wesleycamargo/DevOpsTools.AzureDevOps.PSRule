---
category: Microsoft Azure DevOps Repos
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/nl/Azure.DevOps.Pipelines.Releases.Definition.InheritedPermissions.md
---

# Azure.DevOps.Pipelines.Releases.Definition.InheritedPermissions

## SYNOPSIS

Effectieve gevoelige rechten moeten zijn toegestaan door organisatiebeleid.

## DESCRIPTION

De historische regel-ID blijft behouden. Overerving op zichzelf veroorzaakt geen fout meer. De regel beoordeelt de ACL-hiërarchie, geneste groepen, expliciete toestemmingen en weigeringen en beheerderstoegang in `PermissionEvidence`. Configureer `effectivePermissionPolicies` voor het doeltype `Azure.DevOps.Pipelines.Releases.Definition`. Ontbrekend beleid, ontbrekende ACLs, onvolledige groepsgegevens of ontbrekende beheerdergegevens leiden tot Unknown en worden niet door PSRule beoordeeld. Dit is nooit een geslaagde controle. Beperkte overgeërfde leestoegang is toegestaan; ongeautoriseerde gevoelige rechten falen.

## RECOMMENDATION

Verzamel volledige gegevens en beperk ongeautoriseerde rechten. Behoud legitieme overerving met minimale rechten. Zie [permission evidence](../../../docs/assessment/permission-evidence.md).

## LINKS

- [Permissions and inheritance](https://learn.microsoft.com/en-us/azure/devops/organizations/security/about-permissions)

## ASSESSMENT

Onafhankelijk beoordelingsrisico: **Medium** (severity policy `1.0.0`). De bestaande helpclassificatie en het PSRule-niveau blijven compatibiliteitsmetadata; dit is een afzonderlijke risicoschaal.

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
