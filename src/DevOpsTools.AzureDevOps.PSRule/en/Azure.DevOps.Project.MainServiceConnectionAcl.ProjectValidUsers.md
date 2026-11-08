---
category: Microsoft Azure DevOps Projects
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers.md
---

# Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers

## SYNOPSIS

Project level service connection acl should not have custom permissions for Project Valid
Users

## DESCRIPTION

Azure DevOps allows you to set custom permissions for Project Valid Users on the project
level service connection acl. This is not recommended as it can lead to unintended access
to service connections. It is recommended to use the default permissions for Project Valid
Users and use custom permissions for specific users or custom groups.


Mininum TokenType: `FineGrained`

## RECOMMENDATION

Remove the Project Valid Users group from the service connection acl.

## LINKS

- [Azure DevOps Security best practices](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#scoped-permissions)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.

## EVIDENCE (rule-set 2026.11.06.1)

This rule evaluates direct grants of sensitive namespace-specific permission bits to Project Valid Users. It requires a referenced projectValidUsersPolicies entry with SensitiveMask and optional ApprovedMask. Missing policy or incomplete ACL evidence results in Unknown, not a pass or fail. It is not a substitute for complete effective-permission analysis, including nested groups and administrative bypass.
