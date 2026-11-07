# Organizational assessment policies

Rules evaluate observed configuration. The separately versioned catalog supplies assessment domain, applicability, risk, and correlation metadata. PSRule Error/Warning/Information and the existing five-grade help classification remain compatibility metadata; neither is silently converted into four-grade business risk.

## Explicit policies

Set `assessmentPolicies` in PSRule configuration, keyed by the full rule ID. A policy requires `Reference` identifying the approved organizational decision. `Targets`, when present, contains exact exported ObjectName values. `Required: false` explicitly makes the selected control not applicable. Missing optional policy is NotApplicable; incomplete declared policy or missing target evidence is Unknown. Neither counts as failure or pass.

Public project visibility and anonymous access retain restrictive default policies. An exception scoped to approved Targets does not exempt other targets. Baseline.PublicProject explicitly excludes visibility, anonymous access, and both badge checks. Apply that baseline only to approved public projects.

```powershell
$configuration = @{
    assessmentPolicies = @{
        'Azure.DevOps.Organization.GeneralOverview.GeographySet' = @{
            Reference = 'residency-policy-v1'; Expected = @('United States', 'Europe')
        }
        'Azure.DevOps.Organization.GeneralOverview.TimeZoneSet' = @{
            Reference = 'scheduling-policy-v1'; Expected = 'UTC'
        }
        'Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured' = @{
            Reference = 'billing-policy-v1'; Expected = $false
        }
        'Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays' = @{
            Reference = 'artifact-evidence-v1'; Minimum = 3
        }
        'Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays' = @{
            Reference = 'audit-evidence-v1'; Minimum = 30
        }
        'Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest' = @{
            Reference = 'image-lifecycle-v1'; AllowedImages = @('ubuntu-latest', 'windows-2025')
            RetiredImages = @('ubuntu-18.04')
        }
        'Azure.DevOps.Project.Visibility' = @{
            Reference = 'open-source-approval-v1'; Targets = @('fixture.public-project'); Expected = 'public'
        }
    }
}
$option = New-PSRuleOption -Configuration $configuration
$targets | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Option $option -Outcome All
```

Time-zone and geography policies accept Expected strings or arrays. Billing policies accept an explicit Expected boolean. SSH, guests, and OAuth use the collected `disallow...` field, so Expected=false permits the approved feature. Anonymous access uses `allowAnonymousAccess`, so Expected=true approves it. License-file checks apply only under a referenced licensing policy; Expected defaults to true. For permitted guest access, supply GuestAccessEvidence with Status=Complete, a reviewed Reference, and a Guests list of Descriptor values. The policy must list ApprovedGuestReviews and ApprovedGuests. Unapproved guests fail; absent governance evidence is Unknown. This enrichment must come from the organization's guest access review; the security-setting collector alone cannot establish guest governance.

Missing GHAS license-gated data is Unknown when coverage is required; Licensed=false explicitly marks the vendor-specific feature inapplicable. NoExtraLicense retains its exclusions.

Human-approval policies apply to explicitly covered production Targets. Missing required human approval fails; no policy means optional human approval is not enforced. Generic production protection remains a separate diagnostic and accepts configured automated checks. Both check configuration, not the outcome of a deployment.

## Equivalent controls

GHAS scanning, push-time protection, and human-review policies may list `ApprovedEquivalentControls`, containing reviewed evidence references. A target can supply `EquivalentControls` entries with the exact RuleId, a matching Reference, and `Effective: true`. Approval alone or an ineffective control does not pass. The evidence reference must substantiate coverage for this target, not merely identify a product purchase. A generic scanner is not equivalent to push-time secret prevention.

```json
{
  "EquivalentControls": [{
    "RuleId": "Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes",
    "Reference": "push-prevention-review-v1",
    "Effective": true
  }]
}
```

## Review baselines

- Baseline.SecurityReview selects security controls, including effective permission checks and restrictive default public-exposure policies.
- Baseline.EngineeringReview selects engineering maturity controls, including README and pipeline maintainability.
- Baseline.GovernanceReview selects accountability, documentation, financial continuity, and governance controls.
- Baseline.ConditionalReview selects the 15 opt-in policy controls. Configure their policies before expecting evaluated outcomes.

These explicit lists partition 116 documented controls. The deprecated NoKeyVaultNoSecrets alias is omitted; its replacement NoPlainTextSecrets remains. Unlike the initial 110-control prototype described in the plan, the six corrected effective-permission controls are included in SecurityReview and retain their historical IDs. Existing Default, NoExtraLicense, and PublicProject names remain supported. Default now skips unconfigured optional controls; this is a deliberate denominator change and requires a history annotation.

The runtime debug rule is diagnostic-only and excluded from review baselines and risk scoring. Branch.CommitRecent is an engineering supplement outside the historical 117-entry list. It retains its existing ID and help; neither supplemental rule receives an invented business-risk rating.


## Evidence hardening in rule-set 2026.11.06.1

These checks remain reusable by the general security and governance assessments and future compliance profiles. Existing rule IDs, PSRule levels and assessment risk severities are unchanged.

### Production scope

Skipped production protection, human-approval, and branch-limit diagnostics are NotApplicable for targets outside the configured production scope. The same productionTargets configuration must be passed to both PSRule and ConvertTo-AzDevOpsAssessment. Production targets with missing required evidence remain Unknown; raw engine errors and missing original targets also remain Unknown. An optional human-approval policy remains NotApplicable when it is not required.

The name fallback matches delimited production, prod, prd or live tokens. Main, master, product and liveness do not imply a production environment. Explicitly listed ObjectName values override the name fallback for the specified target type. Use this for systems with custom naming:

    $configuration.productionTargets = @{
        'Azure.DevOps.Pipelines.Environment' = @('org.project.production-environment')
        'Azure.DevOps.ServiceConnection' = @('org.project.production-connection')
    }
    $configuration.productionReleaseEnvironments = @{
        'org.project.release-definition' = @('Production Stage')
    }

A production branch rule passes only when an active Branch control check has a nonempty restricted allowlist of fully qualified refs/heads/... entries. Every entry in that check must be restricted: refs/heads/main,refs/heads/* and refs/heads/main,* fail because the wildcard admits every branch. Bounded patterns such as refs/heads/releases/* remain supported. A separate active restricting check can still establish restriction. Absent/disabled checks fail; incomplete check settings are Unknown. A configured check does not prove it executed or passed during a deployment; collect runtime evidence separately.

### Project Valid Users permissions

The twelve ProjectValidUsers rules no longer compare an ACL allow mask against a hard-coded number. They require a reviewed security-namespace-specific policy with Reference, SensitiveMask, and optional ApprovedMask (default zero), keyed by the full RuleId:

    $configuration.projectValidUsersPolicies = @{
        'Azure.DevOps.Repos.ProjectValidUsers' = @{
            Reference = 'approved-repository-privileges-v1'
            SensitiveMask = $reviewedRepositorySensitiveMask
            ApprovedMask = $reviewedProjectValidUsersAllowedMask
        }
    }

These rules check direct sensitive group grants, accounting for explicit deny. They do not establish complete effective privileges. Use the existing InheritedPermissions controls with complete ACL, identity and bypass evidence for that. Missing policy or incomplete ACL evidence is Unknown. Do not copy numeric permission masks between Azure DevOps security namespaces.

### Service connections and Azure RBAC

A service connection configured at subscription level does not necessarily have subscription-wide Azure RBAC. A resource-group configuration does not prove the identity is least privileged either. Scope now evaluates exact approved cloud RBAC role/scope pairs:

    $configuration.serviceConnectionScopePolicies = @{
        'Azure.DevOps.ServiceConnections.Scope' = @{
            Reference = 'reviewed-cloud-access-policy-v1'
            ApprovedAssignments = @(
                @{ Scope = '/subscriptions/example/resourceGroups/approved'; RoleDefinitionId = 'approved-role-id' }
            )
        }
    }

Externally enriched target evidence must follow this synthetic example:

    $connection.CloudRbacEvidence = @{
        Status = 'Complete'; Reference = 'azure-rbac-export-and-review-v2'
        TargetName = $connection.ObjectName
        PrincipalId = $reviewedServicePrincipalObjectId
        IdentityVerified = $true
        IdentityMapping = @{
            ApplicationId = $reviewedApplicationId
            PrincipalId = $reviewedServicePrincipalObjectId
            TenantId = $reviewedTenantId
            Verified = $true
            Reference = 'reviewed-tenant-service-principal-lookup-v1'
        }
        InheritedAssignmentsIncluded = $true
        RoleDefinitionsComplete = $true
        RoleAssignments = @(
            @{ Scope = '/subscriptions/example/resourceGroups/approved'; RoleDefinitionId = 'approved-role-id' }
        )
    }

The reviewed application ID must match authorization.parameters.serviceprincipalid, and the reviewed tenant ID must match authorization.parameters.tenantid. PrincipalId is the tenant-local service-principal object ID used for Azure RBAC, not the application/client ID. IdentityMapping must record the application-to-object mapping from a lookup in that tenant, with a nonempty evidence Reference and the boolean Verified set to true only after review. The top-level PrincipalId must match the mapping's PrincipalId. All identity IDs must be nonempty GUIDs. Matching display names or copying the application ID into PrincipalId is not verification.

Older evidence without IdentityMapping is intentionally Unknown until re-enriched. Missing endpoint application/tenant IDs, unsupported identity shapes, unverified mappings, and mismatches are Unknown; this evaluator does not silently perform a directory lookup. Evidence must describe all declared RBAC assignments for the mapped principal, including inherited assignments. Neither a verification flag nor this offline evaluation independently authenticates the external evidence source.

The Azure DevOps collector does not retrieve or verify Azure-side RBAC. Evidence must be collected separately and its identity, provenance, inherited assignments and role coverage reviewed. Missing cloud evidence is Unknown, not proof of least privilege. The check covers declared Azure RBAC assignments only, not data-plane permissions or deployment execution.

### Historical comparison

This changes evidence semantics, not risk ratings. RuleSetVersion is now 2026.11.06.1; SeverityPolicyVersion remains 1.1.0. Do not treat changed denominators or newly unknown findings as improvements. Keep raw results and annotate the migration.
