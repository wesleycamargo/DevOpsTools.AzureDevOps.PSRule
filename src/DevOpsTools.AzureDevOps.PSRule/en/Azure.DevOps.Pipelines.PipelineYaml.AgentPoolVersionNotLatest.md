---
category: Repository
severity: Important
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest.md
---

# Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest

## SYNOPSIS

The target should satisfy its applicable organizational policy.

## DESCRIPTION

This control follows `assessmentPolicies['Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest']`. Each explicit policy needs a Reference. Set AllowedImages to the supported approved image names, including intentionally floating images when approved. RetiredImages always fails even if also allowed. Root, stage, and job pools are checked; unavailable pool evidence is Unknown. Missing optional policy is Not applicable; missing evidence for an applicable policy is Unknown. PSRule represents both as not evaluated (`None` with `-Outcome All`); the assessment projection distinguishes them.

## RECOMMENDATION

Configure and apply the referenced policy. See [policy configuration](../../../docs/assessment/policies.md) for examples, scope, and equivalent-control evidence.

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
