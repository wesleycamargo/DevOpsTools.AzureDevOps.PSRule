---
category: Microsoft Azure DevOps Distributed Task
severity: Critical
online version: https://github.com/cloudyspells/PSRule.Rules.AzureDevOps/blob/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Tasks.VariableGroup.NoKeyVaultNoSecrets.md
---

# Azure.DevOps.Tasks.VariableGroup.NoKeyVaultNoSecrets

## SYNOPSIS

Variable groups should not expose credentials.

## DESCRIPTION

This rule ID is deprecated and retained as an alias of `Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets`. Both diagnostics map to the same secret-exposure risk group. Masked Azure DevOps secret variables (`isSecret: true`, `value: null`) are accepted without a Key Vault requirement. Unmasked declared secrets and values matching credential patterns fail. Pattern detection cannot prove that arbitrary plaintext is not a secret. Missing variable collection is Unknown in assessment output and not evaluated by PSRule; it is never a pass.

Minimum TokenType: `ReadOnly`

## RECOMMENDATION

Use masked Azure DevOps secret variables or Key Vault references. Rotate exposed credentials. Restore collection permissions when evidence is unavailable.

## LINKS

- [Secret variables](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-secret-variables)
