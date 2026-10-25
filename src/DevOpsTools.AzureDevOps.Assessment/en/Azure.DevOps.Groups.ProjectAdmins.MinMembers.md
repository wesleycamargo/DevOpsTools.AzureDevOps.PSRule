---
category: Microsoft Azure DevOps Pipelines
severity: Severe
online version: https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps/blob/main/src/DevOpsTools.AzureDevOps.Assessment/en/Azure.DevOps.Groups.ProjectAdmins.MinMembers.md
---

# Azure.DevOps.Groups.ProjectAdmins.MinMembers

## SYNOPSIS

The project administrators group should have at least 2 members.

## DESCRIPTION

The project administrators group should have at least 2 members. This ensures that there is more than one person who can manage the project. This rule applies to the default project administrators group.


Mininum TokenType: `ReadOnly`

This setting is configurable and can be changed to suit your organization's needs with `ProjectAdminsMinMembers` in the `configuration` section of your ps-rule.yaml file.

## RECOMMENDATION

Consider adding more than one member to the project administrators group.

## LINKS

- [Azure DevOps Security best practices - Tasks](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#tasks)

## ASSESSMENT

Independent assessment risk: **Medium** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.

An approved one-admin operating model with centralized recovery or break-glass can set `ProjectAdminsMinMembers: 1`. Record the access/recovery policy reference in assessment configuration and retain evidence that the recovery arrangement works. The member count alone does not establish privilege safety.
