BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
    function New-FixtureResult {
        param([string]$Rule, [string]$Type, [string]$Name = 'fixture', [string]$Outcome = 'Fail')
        [pscustomobject]@{ RuleName = $Rule; TargetType = $Type; TargetName = "$Type/$Name"; Outcome = $Outcome; OutcomeReason = 'Processed'; Reason = @('synthetic diagnostic') }
    }
}
Describe 'Assessment catalog and risk projection' -Tag 'Unit' {
    It 'versions the corrected review evidence semantics separately from severity policy' {
        $catalog = Get-AzDevOpsAssessmentCatalog
        $catalog.RuleSetVersion | Should -Be '2026.11.07.1'
        $catalog.SeverityPolicyVersion | Should -Be '1.1.0'
        $raw = @(New-FixtureResult 'Azure.DevOps.Repos.Branch.HasBranchPolicy' 'Azure.DevOps.Repo.Branch')
        $current = ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project'
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Get-AzDevOpsAssessmentCatalog {
            $old = Get-Content "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/Assessment/catalog.json" -Raw | ConvertFrom-Json
            $old.RuleSetVersion = '2026.11.06.1'
            $old
        }
        $previous = ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project'
        $comparison = Compare-AzDevOpsAssessment $previous $current
        $comparison.Comparable | Should -BeFalse
        $comparison.SecurityScoreDelta | Should -BeNullOrEmpty
    }

    It 'projects skipped nonproduction controls as NotApplicable for <Type>' -ForEach @(
        @{ Type = 'Azure.DevOps.Pipelines.Environment'; Prefix = 'Azure.DevOps.Pipelines.Environments' }
        @{ Type = 'Azure.DevOps.ServiceConnection'; Prefix = 'Azure.DevOps.ServiceConnections' }
    ) {
        foreach ($scenario in @(
            @{ Name = 'development'; Explicit = $false }
            @{ Name = 'production'; Explicit = $true }
        )) {
            $target = [pscustomobject]@{
                ObjectType = $Type; ObjectName = 'fixture.target'; name = $scenario.Name
                Checks = $null
            }
            $configuration = @{
                assessmentPolicies = @{
                    "$Prefix.ProductionHumanApproval" = @{ Reference = 'required-human-review-v1' }
                }
            }
            if ($scenario.Explicit) {
                $configuration.productionTargets = @{ $Type = @() }
            }
            $rules = @(
                "$Prefix.ProductionCheckProtection"
                "$Prefix.ProductionHumanApproval"
                "$Prefix.ProductionBranchLimit"
            )
            $option = New-PSRuleOption -Configuration $configuration
            $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule `
                -Name $rules -Option $option -Outcome All -Culture en -ErrorAction Stop)
            $raw.Count | Should -Be 3
            @($raw | Where-Object Outcome -NE 'None').Count | Should -Be 0
            $before = $raw | ConvertTo-Json -Depth 30
            $report = ConvertTo-AzDevOpsAssessment -Result $raw -TargetObject @($target) `
                -ScopeId 'fixture/project' -Configuration $configuration
            $report.Findings.Count | Should -Be 3
            @($report.Findings | Where-Object Outcome -NE 'NotApplicable').Count | Should -Be 0
            @($report.Findings | Where-Object ReasonCode -NE 'NonProductionTarget').Count | Should -Be 0
            $report.Summary.UnknownSecurityObjectives | Should -Be 0
            $report.Summary.NotApplicableObjectives | Should -Be 3
            $report.Summary.KnownFailedSecurityWeight | Should -Be 0
            $report.Summary.SecurityScore | Should -BeNullOrEmpty
            ($raw | ConvertTo-Json -Depth 30) | Should -Be $before
        }
    }

    It 'keeps missing production evidence Unknown and optional human approval NotApplicable' -ForEach @(
        @{ Type = 'Azure.DevOps.Pipelines.Environment'; Prefix = 'Azure.DevOps.Pipelines.Environments' }
        @{ Type = 'Azure.DevOps.ServiceConnection'; Prefix = 'Azure.DevOps.ServiceConnections' }
    ) {
        $target = [pscustomobject]@{
            ObjectType = $Type; ObjectName = 'fixture.custom'; name = 'development'; Checks = $null
        }
        $configuration = @{
            productionTargets = @{ $Type = @('fixture.custom') }
            assessmentPolicies = @{
                "$Prefix.ProductionHumanApproval" = @{ Reference = 'required-human-review-v1' }
            }
        }
        $rules = @("$Prefix.ProductionCheckProtection", "$Prefix.ProductionHumanApproval", "$Prefix.ProductionBranchLimit")
        $option = New-PSRuleOption -Configuration $configuration
        $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule `
            -Name $rules -Option $option -Outcome All -Culture en -ErrorAction Stop)
        $report = ConvertTo-AzDevOpsAssessment $raw @($target) 'fixture/project' -Configuration $configuration
        $report.Findings.Count | Should -Be 3
        @($report.Findings | Where-Object Outcome -NE 'Unknown').Count | Should -Be 0
        $report.Summary.UnknownSecurityObjectives | Should -Be 3
        $report.Summary.SecurityScore | Should -BeNullOrEmpty

        $configuration.assessmentPolicies.Clear()
        $option = New-PSRuleOption -Configuration $configuration
        $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule `
            -Name $rules -Option $option -Outcome All -Culture en -ErrorAction Stop)
        $report = ConvertTo-AzDevOpsAssessment $raw @($target) 'fixture/project' -Configuration $configuration
        ($report.Findings | Where-Object RuleId -EQ "$Prefix.ProductionHumanApproval").Outcome | Should -Be 'NotApplicable'
        @($report.Findings | Where-Object Outcome -EQ 'Unknown').Count | Should -Be 2
    }

    It 'does not hide errors, missing targets, or unexecuted production diagnostics' {
        $type = 'Azure.DevOps.Pipelines.Environment'
        $rule = 'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection'
        $target = [pscustomobject]@{
            ObjectType = $type; ObjectName = 'fixture'; name = 'development'; Checks = @()
        }
        foreach ($reason in 'Error', 'Inconclusive') {
            $raw = New-FixtureResult $rule $type 'fixture' 'None'
            $raw.OutcomeReason = $reason
            (ConvertTo-AzDevOpsAssessment @($raw) @($target) 'fixture/project').Findings[0].Outcome | Should -Be 'Unknown'
        }
        $raw = New-FixtureResult $rule $type 'fixture' 'None'
        $report = ConvertTo-AzDevOpsAssessment @($raw) @() 'fixture/project'
        $report.Findings[0].Outcome | Should -Be 'Unknown'
        $report.Findings[0].ReasonCode | Should -Be 'OriginalTargetUnavailable'

        $target.name = 'production'
        $report = ConvertTo-AzDevOpsAssessment @($raw) @($target) 'fixture/project'
        $report.Findings[0].Outcome | Should -Be 'Unknown'
        $report.Findings[0].ReasonCode | Should -Be 'RawDiagnosticNotEvaluated'
    }

    It 'maps all 117 documented IDs uniquely and records supplemental runtime rules explicitly' {
        $catalog = Get-AzDevOpsAssessmentCatalog
        $catalog.Rules.Count | Should -Be 117
        @($catalog.Rules.RuleId | Sort-Object -Unique).Count | Should -Be 117
        $inventory = Get-Content "$PSScriptRoot/../docs/assessment/source-inventory.json" -Raw | ConvertFrom-Json
        @(Compare-Object @($inventory.rules | Where-Object documented | Select-Object -ExpandProperty ruleId) $catalog.Rules.RuleId).Count | Should -Be 0
        @($catalog.SupplementalRules).Count | Should -Be 2
        @($catalog.Rules | Where-Object { $_.AssessmentSeverity -in 'High', 'Critical' -and -not $_.ExposureRationale }).Count | Should -Be 0
        @($catalog.Rules | Where-Object { -not $_.AssessmentSeverity }).Count | Should -Be 0
    }
    It 'deduplicates same-target branch exposures while retaining both raw diagnostic identities' {
        $type = 'Azure.DevOps.Repo.Branch'
        $raw = @(
            New-FixtureResult 'Azure.DevOps.Repos.Branch.HasBranchPolicy' $type
            New-FixtureResult 'Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled' $type
        )
        $before = $raw | ConvertTo-Json -Depth 10
        $report = ConvertTo-AzDevOpsAssessment -Result $raw -TargetObject @() -ScopeId 'fixture/project'
        $report.Findings.Count | Should -Be 2
        $report.RiskObjectives.Count | Should -Be 1
        $report.Summary.KnownFailedSecurityWeight | Should -Be 4
        $report.RiskObjectives[0].DiagnosticRuleIds.Count | Should -Be 2
        ($raw | ConvertTo-Json -Depth 10) | Should -Be $before
    }
    It 'does not correlate separate target branches' {
        $type = 'Azure.DevOps.Repo.Branch'
        $raw = @(
            New-FixtureResult 'Azure.DevOps.Repos.Branch.HasBranchPolicy' $type 'branch-a'
            New-FixtureResult 'Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled' $type 'branch-b'
        )
        (ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project').RiskObjectives.Count | Should -Be 2
    }
    It 'correlates a common missing production gate without merging distinct requirements' {
        $type = 'Azure.DevOps.Pipelines.Environment'
        $target = [pscustomobject]@{ ObjectType = $type; ObjectName = 'fixture'; Checks = @() }
        $raw = @(
            New-FixtureResult 'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection' $type
            New-FixtureResult 'Azure.DevOps.Pipelines.Environments.ProductionHumanApproval' $type
        )
        (ConvertTo-AzDevOpsAssessment $raw @($target) 'fixture/project').RiskObjectives.Count | Should -Be 1
        $target.Checks = @(@{ type = @{ name = 'InvokeRESTAPI' }; settings = @{} })
        $raw[0].Outcome = 'Pass'
        $report = ConvertTo-AzDevOpsAssessment $raw @($target) 'fixture/project'
        $report.RiskObjectives.Count | Should -Be 2
        @($report.RiskObjectives | Where-Object Outcome -EQ 'Fail').Count | Should -Be 1
    }
    It 'keeps missing evidence visible and prevents a complete security score' {
        $type = 'Azure.DevOps.Pipeline'
        $target = [pscustomobject]@{ ObjectType = $type; ObjectName = 'fixture' }
        $raw = @(New-FixtureResult 'Azure.DevOps.Pipelines.Core.InheritedPermissions' $type 'fixture' 'None')
        $report = ConvertTo-AzDevOpsAssessment $raw @($target) 'fixture/project'
        $report.Findings[0].Outcome | Should -Be 'Unknown'
        $report.Summary.UnknownSecurityObjectives | Should -Be 1
        $report.Summary.SecurityScore | Should -BeNullOrEmpty
    }
    It 'does not count optional absent policy as a security failure' {
        $type = 'Azure.DevOps.Organization.GeneralOverview'
        $target = [pscustomobject]@{ ObjectType = $type; ObjectName = 'fixture'; geography = 'United States' }
        $raw = @(New-FixtureResult 'Azure.DevOps.Organization.GeneralOverview.GeographySet' $type 'fixture' 'None')
        $report = ConvertTo-AzDevOpsAssessment $raw @($target) 'fixture/project'
        $report.Findings[0].Outcome | Should -Be 'NotApplicable'
        $report.Summary.NotApplicableObjectives | Should -Be 1
        $report.Summary.KnownFailedSecurityWeight | Should -Be 0
    }
    It 'excludes engineering and financial governance from security scoring' {
        $raw = @(
            New-FixtureResult 'Azure.DevOps.Repos.Readme' 'Azure.DevOps.Repo'
            New-FixtureResult 'Azure.DevOps.Organization.GeneralBillingSettings.SubscriptionActive' 'Azure.DevOps.Organization.GeneralBillingSettings'
        )
        $report = ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project'
        $report.Findings.Count | Should -Be 2
        $report.Summary.KnownFailedSecurityWeight | Should -Be 0
        $report.Summary.SecurityScore | Should -BeNullOrEmpty
    }
    It 'applies the supplied broader proposal to a verified failing diagnostic' {
        $raw = @(New-FixtureResult 'Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess' 'Azure.DevOps.Organization.Security.Policies')
        $report = ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project'
        $report.Findings[0].AssessmentSeverity | Should -Be 'High'
        $report.Summary.UnclassifiedSecurityObjectives | Should -Be 0
        $report.Summary.KnownFailedSecurityWeight | Should -Be 4
        $report.Summary.SecurityScore | Should -Be 0
    }
    It 'does not hide an unmapped new diagnostic behind a complete score' {
        $raw = @(
            New-FixtureResult 'Azure.DevOps.Repos.Branch.HasBranchPolicy' 'Azure.DevOps.Repo.Branch' 'fixture' 'Pass'
            New-FixtureResult 'Azure.DevOps.NewControl' 'Azure.DevOps.Repo.Branch'
        )
        $report = ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project'
        $report.Summary.UnmappedDiagnosticCount | Should -Be 1
        $report.Summary.SecurityScore | Should -BeNullOrEmpty
    }
    It 'invalidates history comparisons when policy or denominator changes' {
        $raw = @(New-FixtureResult 'Azure.DevOps.Repos.Branch.HasBranchPolicy' 'Azure.DevOps.Repo.Branch')
        $previous = ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project'
        $same = ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project'
        (Compare-AzDevOpsAssessment $previous $same).Comparable | Should -Be $true
        $changed = ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project' -Configuration @{ policyRevision = 'v2' }
        (Compare-AzDevOpsAssessment $previous $changed).Comparable | Should -Be $false
        $raw += New-FixtureResult 'Azure.DevOps.Repos.Branch.HasBranchPolicy' 'Azure.DevOps.Repo.Branch' 'another'
        $changed = ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project'
        (Compare-AzDevOpsAssessment $previous $changed).SecurityScoreDelta | Should -BeNullOrEmpty
        (Compare-AzDevOpsAssessment $previous $changed).Comparable | Should -Be $false
    }
    It 'retains missing versus disabled branch policy diagnostics from actual rule execution' {
        $targets = @(
            [pscustomobject]@{ ObjectType = 'Azure.DevOps.Repo.Branch'; ObjectName = 'missing'; BranchPolicy = @() }
            [pscustomobject]@{ ObjectType = 'Azure.DevOps.Repo.Branch'; ObjectName = 'disabled'; BranchPolicy = @(@{ isEnabled = $false }) }
        )
        $rules = 'Azure.DevOps.Repos.Branch.HasBranchPolicy', 'Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled'
        $raw = @($targets | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $rules -Outcome All -Culture en -ErrorAction Stop)
        $report = ConvertTo-AzDevOpsAssessment $raw $targets 'fixture/project'
        $report.Findings.Count | Should -Be 4
        $report.RiskObjectives.Count | Should -Be 2
        @($report.Findings | Where-Object { $_.TargetName -like '*/disabled' -and $_.Outcome -eq 'Pass' }).Count | Should -Be 1
    }
}
AfterAll { Remove-Module DevOpsTools.AzureDevOps.PSRule -Force }
