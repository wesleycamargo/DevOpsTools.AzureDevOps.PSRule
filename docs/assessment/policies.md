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
