---
category: Microsoft Azure DevOps Organization
severity: Information
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.Debug.md
---

# Azure.DevOps.Organization.Security.Policies.Debug

## SYNOPSIS

Inspect the organization security policy target and its properties.

## DESCRIPTION

This informational rule writes the target object type, property names, and selected
policy values to verbose output. It passes when this inspection completes and
fails if an exception occurs. A passing result does not establish that the policy
values satisfy the security rules.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Ensure the input JSON contains the expected organization security policy object
and review the individual policy rule results.
