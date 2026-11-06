---
category: Microsoft Azure DevOps Variable Groups
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Tasks.VariableGroup.ProjectValidUsers.md
---

# Azure.DevOps.Tasks.VariableGroup.ProjectValidUsers

## SYNOPSIS

Variable groups should not be assigned directly to the Project Valid Users
group.

## DESCRIPTION

Variable groups should not be assigned directly to the Project Valid Users
group. This group is inherited by all users in the project and will grant
access to all variables in the group.

Mininum TokenType: `FineGrained`

## RECOMMENDATION

Remove the Project Valid Users group from the variable group acl.

## LINKS

- [Azure DevOps Security best practices](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#scoped-permissions)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.

## EVIDENCE (rule-set 2026.11.06.1)

This rule evaluates direct grants of sensitive namespace-specific permission bits to Project Valid Users. It requires a referenced projectValidUsersPolicies entry with SensitiveMask and optional ApprovedMask. Missing policy or incomplete ACL evidence results in Unknown, not a pass or fail. It is not a substitute for complete effective-permission analysis, including nested groups and administrative bypass.
