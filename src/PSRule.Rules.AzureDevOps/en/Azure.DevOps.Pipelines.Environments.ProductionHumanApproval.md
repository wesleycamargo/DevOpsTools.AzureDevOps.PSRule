---
category: Microsoft Azure DevOps Pipelines
severity: Severe
online version: https://github.com/cloudyspells/PSRule.Rules.AzureDevOps/blob/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Pipelines.Environments.ProductionHumanApproval.md
---

# Azure.DevOps.Pipelines.Environments.ProductionHumanApproval

## SYNOPSIS

The target should satisfy its applicable organizational policy.

## DESCRIPTION

This production-only rule uses the `IsProduction` name selector. Development resources are skipped. Name matching is a convention; configure names or suppressions to match your production inventory.

This control follows `assessmentPolicies['Azure.DevOps.Pipelines.Environments.ProductionHumanApproval']`. Each explicit policy needs a Reference. A referenced policy makes human review required for the selected Targets. A configured enabled Approval check with approvers satisfies it. ApprovedEquivalentControls can reference approved effective automated review when policy allows it. Missing optional policy is Not applicable; missing evidence for an applicable policy is Unknown. PSRule represents both as not evaluated (`None` with `-Outcome All`); the assessment projection distinguishes them.

Mininum TokenType: `FineGrained`

## RECOMMENDATION

Configure and apply the referenced policy. See [policy configuration](../../../docs/assessment/policies.md) for examples, scope, and equivalent-control evidence.

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
