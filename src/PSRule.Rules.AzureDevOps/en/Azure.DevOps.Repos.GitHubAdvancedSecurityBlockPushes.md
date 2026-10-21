---
category: Microsoft Azure DevOps Repos
severity: Important
online version: https://github.com/cloudyspells/PSRule.Rules.AzureDevOps/blob/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes.md
---

# Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes

## SYNOPSIS

The target should satisfy its applicable organizational policy.

## DESCRIPTION

This control follows `assessmentPolicies['Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes']`. Each explicit policy needs a Reference. Expected defaults to true for required licensed push prevention. Licensed=false makes this vendor-specific check inapplicable. ApprovedEquivalentControls can reference reviewed effective push-time prevention. Missing optional policy is Not applicable; missing evidence for an applicable policy is Unknown. PSRule represents both as not evaluated (`None` with `-Outcome All`); the assessment projection distinguishes them.

## RECOMMENDATION

Configure and apply the referenced policy. See [policy configuration](../../../docs/assessment/policies.md) for examples, scope, and equivalent-control evidence.

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
