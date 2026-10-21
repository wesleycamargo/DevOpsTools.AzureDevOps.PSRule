---
category: Microsoft Azure DevOps Pipelines
severity: Severe
online version: https://github.com/cloudyspells/PSRule.Rules.AzureDevOps/blob/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Pipelines.Environments.ProductionCheckProtection.md
---

# Azure.DevOps.Pipelines.Environments.ProductionCheckProtection

## SYNOPSIS

Production resources should have a configured protection gate.

## DESCRIPTION

An enabled configured protection check satisfies this diagnostic, including an automated check. Human approval is a separate policy. Empty checks fail; disabled checks fail; unavailable or incomplete check collection is Unknown and not evaluated by PSRule. This verifies gate configuration, not successful execution of a deployment. Raw findings remain distinct; only the same target's common missing or disabled gate is correlated in assessment scoring.

## RECOMMENDATION

Configure an enabled protection check and retain deployment execution evidence.

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.0.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
