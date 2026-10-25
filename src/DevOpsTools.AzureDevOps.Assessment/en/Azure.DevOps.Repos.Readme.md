---
category: Microsoft Azure DevOps Repos
severity: Informational
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Repos.Readme.md
---

# AzureDevOps.Repos.Readme

## SYNOPSIS

Use a README.md file in the default branch to explain the project and provide
information.

## DESCRIPTION

When someone visits the repository homepage the README.md in the default branch
is automatically shown.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Consider creating a README.md file in repository default branch to provide
information about the project.

## LINKS

- [Writing a README](https://opensource.guide/starting-a-project/#writing-a-readme)

## ASSESSMENT

Independent assessment risk: **Low** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.
