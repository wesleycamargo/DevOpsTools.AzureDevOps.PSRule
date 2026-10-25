BeforeAll {
    Import-Module "$PSScriptRoot/../src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psd1" -Force
    function New-FixtureResult {
        param([string]$Rule, [string]$Type, [string]$Name = 'fixture', [string]$Outcome = 'Fail')
        [pscustomobject]@{ RuleName = $Rule; TargetType = $Type; TargetName = "$Type/$Name"; Outcome = $Outcome; OutcomeReason = 'Processed'; Reason = @('synthetic diagnostic') }
    }
}
Describe 'Assessment catalog and risk projection' -Tag 'Unit' {
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
        $raw = @($targets | Invoke-PSRule -Module PSRule.Rules.AzureDevOps -Name $rules -Outcome All -Culture en -ErrorAction Stop)
        $report = ConvertTo-AzDevOpsAssessment $raw $targets 'fixture/project'
        $report.Findings.Count | Should -Be 4
        $report.RiskObjectives.Count | Should -Be 2
        @($report.Findings | Where-Object { $_.TargetName -like '*/disabled' -and $_.Outcome -eq 'Pass' }).Count | Should -Be 1
    }
}
AfterAll { Remove-Module PSRule.Rules.AzureDevOps -Force }
