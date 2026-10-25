---
category: Microsoft Azure DevOps Pipelines
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.Assessment/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Pipelines.Settings.StatusBadgesPrivate.md
---

# Azure.DevOps.Pipelines.Settings.StatusBadgesPrivate

## SYNOPSIS

Status badges should not be publicly accessible.

## DESCRIPTION

Status badges are publicly accessible by default. This means anyone with the URL can view
the status of a pipeline. Consider restricting access to status badges to prevent
unauthorized access.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Consider restricting access to status badges to prevent unauthorized access.

## LINKS

- [Azure DevOps Security best practices](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#tasks)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
