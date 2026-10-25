---
category: Repository
severity: Important
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Pipelines.Core.UseYamlDefinition.md
---

# Use YAML pipeline definitions

## SYNOPSIS

Use YAML pipeline definitions to define build and release pipelines.

## DESCRIPTION

Using YAML pipeline definitions allows you to define build and release pipelines
as code. This allows you to manage changes to your pipelines in the same way as
you manage changes to your application code. You can use source control to view
changes to your pipelines, roll back to previous versions, and easily collaborate
with other developers on your team.

Mininum TokenType: `ReadOnly

## RECOMMENDATION

Use YAML pipeline definitions to define build and release pipelines.

## LINKS

- [Azure Pipelines YAML schema reference](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema)
- [Azure DevOps security best practices](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#definitions)

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
