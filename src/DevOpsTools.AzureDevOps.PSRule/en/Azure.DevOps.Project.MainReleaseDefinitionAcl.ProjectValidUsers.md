---
category: Microsoft Azure DevOps Projects
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers.md
---

# Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers

## SYNOPSIS

Project level release definition acl should not have custom permissions for Project Valid
Users

## DESCRIPTION

Project level release definition acl should not have custom permissions for Project Valid
Users. The Project Valid Users group is a special group that is automatically
created when a project is created. It contains all users and groups that have
been added to the project. This group should not be used to grant permissions to
the release definitions.

Mininum TokenType: `FineGrained`

## RECOMMENDATION

Remove the Project Valid Users group from the release definition acl.

## LINKS

- [Azure DevOps Security best practices](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#scoped-permissions)

## ASSESSMENT

Independent assessment risk: **High** (severity policy `1.1.0`). The legacy help severity above and PSRule level Warning remain compatibility metadata; they are not the four-grade assessment scale.

## EVIDENCE (rule-set 2026.11.06.1)

This rule evaluates direct grants of sensitive namespace-specific permission bits to Project Valid Users. It requires a referenced projectValidUsersPolicies entry with SensitiveMask and optional ApprovedMask. Missing policy or incomplete ACL evidence results in Unknown, not a pass or fail. It is not a substitute for complete effective-permission analysis, including nested groups and administrative bypass.
