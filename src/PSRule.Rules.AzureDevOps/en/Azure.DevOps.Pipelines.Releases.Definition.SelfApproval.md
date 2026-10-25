---
category: Microsoft Azure DevOps Pipelines
severity: Severe
online version: https://github.com/cloudyspells/PSRule.Rules.AzureDevOps/blob/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Pipelines.Releases.Definition.SelfApproval.md
---

# Azure.DevOps.Pipelines.Releases.Definition.SelfApproval

## SYNOPSIS

An environment scoped to production should not allow self approval.

## DESCRIPTION

An environment scoped to production should not allow self approval. This
rule checks if a release stage environment scoped to production has
self approval enabled.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Consider disabling self approval for the environment.

## LINKS

- [Release Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/release/?view=azure-devops)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
