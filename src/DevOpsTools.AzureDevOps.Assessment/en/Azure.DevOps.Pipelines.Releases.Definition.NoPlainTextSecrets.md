---
category: Microsoft Azure DevOps Pipelines
severity: Critical
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Pipelines.Releases.Definition.NoPlainTextSecrets.md
---

# Azure.DevOps.Pipelines.Releases.Definition.NoPlainTextSecrets

## SYNOPSIS

Release pipeline variables should not contain secrets in plain text.

## DESCRIPTION

Detection is heuristic and limited to exported values. Structured credential patterns and the signed 84-character Azure DevOps PAT format are checked. Arbitrary 32/40-character values and legacy unsigned PATs cannot reliably be identified by length alone and are not flagged. A passing result does not establish the absence of secrets. Failure reasons do not include matched values.

Release pipeline variables should not contain secrets in plain text. Secrets should be
stored in Azure Key Vault and referenced in the variable group. This will prevent the
secret from being exposed in the build logs. If the secret is stored in plain text, it
will be exposed in the build logs.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Consider storing secrets in Azure Key Vault and referencing them in the variable group.

## LINKS

- [Azure DevOps Security best practices - Tasks](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#tasks)

## ASSESSMENT

Independent assessment risk: **Critical** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
