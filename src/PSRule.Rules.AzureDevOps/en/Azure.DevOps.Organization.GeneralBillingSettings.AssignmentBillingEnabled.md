---
category: Microsoft Azure DevOps Organization
severity: Severe
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled.md
---

# Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled

## SYNOPSIS

The target should satisfy its applicable organizational policy.

## DESCRIPTION

This control follows `assessmentPolicies['Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled']`. Each explicit policy needs a Reference. Set Expected to the approved boolean assignment-billing preference. Missing optional policy is Not applicable; missing evidence for an applicable policy is Unknown. PSRule represents both as not evaluated (`None` with `-Outcome All`); the assessment projection distinguishes them.

## RECOMMENDATION

Configure and apply the referenced policy. See [policy configuration](../../../docs/assessment/policies.md) for examples, scope, and equivalent-control evidence.

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.0.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
