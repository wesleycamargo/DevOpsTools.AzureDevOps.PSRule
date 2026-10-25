---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess.md
---

# Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess

## SYNOPSIS

The target should satisfy its applicable organizational policy.

## DESCRIPTION

This control follows `assessmentPolicies['Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess']`. Each explicit policy needs a Reference. Expected refers to allowAnonymousAccess: false prohibits anonymous access; true requires an explicit approval. Outside approved Targets, the default prohibition still applies. Baseline.PublicProject excludes this control. Missing optional policy is Not applicable; missing evidence for an applicable policy is Unknown. PSRule represents both as not evaluated (`None` with `-Outcome All`); the assessment projection distinguishes them.

## RECOMMENDATION

Configure and apply the referenced policy. See [policy configuration](../../../docs/assessment/policies.md) for examples, scope, and equivalent-control evidence.

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
