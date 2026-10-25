---
category: Microsoft Azure DevOps Pipelines
severity: Critical
online version: https://github.com/cloudyspells/PSRule.Rules.AzureDevOps/blob/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets.md
---

# Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets

## SYNOPSIS

Variable groups should not expose credentials.

## DESCRIPTION

Masked Azure DevOps secret variables (`isSecret: true`, `value: null`) are accepted without a Key Vault requirement. Unmasked declared secrets and values matching credential patterns fail. Pattern detection cannot prove that arbitrary plaintext is not a secret. Missing variable collection is Unknown in assessment output and not evaluated by PSRule; it is never a pass.

Detection is heuristic and limited to exported values. Structured credential patterns and the signed 84-character Azure DevOps PAT format are checked. Arbitrary 32/40-character values and legacy unsigned PATs cannot reliably be identified by length alone and are not flagged. A passing result does not establish the absence of secrets. Failure reasons do not include matched values.

Minimum TokenType: `ReadOnly`

## RECOMMENDATION

Use masked Azure DevOps secret variables or Key Vault references. Rotate exposed credentials. Restore collection permissions when evidence is unavailable.

## LINKS

- [Secret variables](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-secret-variables)

## ASSESSMENT

Independent assessment risk: **Critical** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
