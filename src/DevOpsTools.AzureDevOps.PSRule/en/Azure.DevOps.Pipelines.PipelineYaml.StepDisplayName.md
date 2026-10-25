---
category: Repository
severity: Informational
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.PipelineYaml.StepDisplayName.md
---

# Azure.DevOps.Pipelines.PipelineYaml.StepDisplayName

## SYNOPSIS

Pipeline steps should have a display name.

## DESCRIPTION

Pipeline steps should have a display name. This ensures that the pipeline is
easier to read and understand.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Consider adding a display name to all steps.

## LINKS

- [Azure Pipelines YAML schema reference](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
