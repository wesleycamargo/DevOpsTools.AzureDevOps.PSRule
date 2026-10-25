---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess.md
---

# Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess

## SYNOPSIS

The target should satisfy its applicable organizational policy.

## DESCRIPTION

This control follows `assessmentPolicies['Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess']`. Each explicit policy needs a Reference. Set Expected=false for approved governed guest access, or true when guest access is prohibited. Permitted guest access also requires complete GuestAccessEvidence, a Reference listed in ApprovedGuestReviews, and guest descriptors listed in ApprovedGuests. Unapproved guests fail; missing governance evidence is Unknown. Missing optional policy is Not applicable; missing evidence for an applicable policy is Unknown. PSRule represents both as not evaluated (`None` with `-Outcome All`); the assessment projection distinguishes them.

## RECOMMENDATION

Configure and apply the referenced policy. See [policy configuration](../../../docs/assessment/policies.md) for examples, scope, and equivalent-control evidence.

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Error remain compatibility metadata; they are not the four-grade assessment scale.
