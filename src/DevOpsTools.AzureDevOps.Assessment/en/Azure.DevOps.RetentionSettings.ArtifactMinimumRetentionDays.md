---
category: Microsoft Azure DevOps Retention Settings
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays.md
---

# Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays

## SYNOPSIS

The target should satisfy its applicable organizational policy.

## DESCRIPTION

This control follows `assessmentPolicies['Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays']`. Each explicit policy needs a Reference. Set Minimum to the approved artifact-retention threshold for the evidence class. No fixed seven-day default applies without policy. Missing optional policy is Not applicable; missing evidence for an applicable policy is Unknown. PSRule represents both as not evaluated (`None` with `-Outcome All`); the assessment projection distinguishes them.

## RECOMMENDATION

Configure and apply the referenced policy. See [policy configuration](../../../docs/assessment/policies.md) for examples, scope, and equivalent-control evidence.

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
