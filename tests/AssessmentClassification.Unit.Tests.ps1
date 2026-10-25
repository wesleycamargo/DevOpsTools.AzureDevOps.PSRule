BeforeAll {
    Import-Module "$PSScriptRoot/../src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psd1" -Force
    $proposal = Get-Content "$PSScriptRoot/../docs/assessment/proposed-rule-risk-policy.json" -Raw | ConvertFrom-Json
    $changes = Get-Content "$PSScriptRoot/../docs/assessment/proposed-rule-changes.json" -Raw | ConvertFrom-Json
}
Describe 'Supplied assessment classifications' -Tag 'Unit' {
    It 'matches every supplied rating and retains its source severity and applicability guidance' {
        $catalog = Get-AzDevOpsAssessmentCatalog
        $proposal.rules.Count | Should -Be 117
        @($proposal.rules.id | Sort-Object -Unique).Count | Should -Be 117
        @(Compare-Object $proposal.rules.id $catalog.Rules.RuleId).Count | Should -Be 0
        foreach ($proposed in $proposal.rules) {
            $rule = $catalog.Rules | Where-Object RuleId -EQ $proposed.id
            $rule.AssessmentSeverity | Should -Be $proposed.proposedSeverity
            $rule.LegacyHelpSeverity | Should -Be $proposed.sourceSeverity
            $rule.ApplicabilityGuidance | Should -Be $proposed.applicability
            $rule.ExposureRationale | Should -Match ([regex]::Escape($proposed.riskRationale))
            if ($proposed.proposedReviewBaseline -in 'Security', 'Engineering', 'Governance') {
                $rule.Domain | Should -Be $proposed.proposedReviewBaseline
            }
            $help = Get-Content "$PSScriptRoot/../src/PSRule.Rules.AzureDevOps/en/$($rule.RuleId).md" -Raw
            $help | Should -Match ([regex]::Escape("Independent assessment risk: **$($rule.AssessmentSeverity)**"))
            $help | Should -Match ([regex]::Escape($catalog.SeverityPolicyVersion))
        }
        foreach ($change in $changes.changes) {
            ($catalog.Rules | Where-Object RuleId -EQ $change.rule).AssessmentSeverity | Should -Be $change.proposed_severity
        }
    }
    It 'counts exposed plaintext secrets once at Critical despite the deprecated Medium alias' {
        $type = 'Azure.DevOps.Tasks.VariableGroup'
        $raw = foreach ($id in 'NoKeyVaultNoSecrets', 'NoPlainTextSecrets') {
            [pscustomobject]@{ RuleName = "Azure.DevOps.Tasks.VariableGroup.$id"; TargetType = $type; TargetName = "$type/fixture"; Outcome = 'Fail'; OutcomeReason = 'Processed'; Reason = @('exposed synthetic credential') }
        }
        $report = ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project'
        $report.Findings.Count | Should -Be 2
        $report.RiskObjectives.Count | Should -Be 1
        $report.RiskObjectives[0].AssessmentSeverity | Should -Be 'Critical'
        $report.Summary.KnownFailedSecurityWeight | Should -Be 8
    }
    It 'does not interpret a severity-policy migration as a numerical security improvement' {
        $raw = @([pscustomobject]@{ RuleName = 'Azure.DevOps.Repos.Branch.HasBranchPolicy'; TargetType = 'Azure.DevOps.Repo.Branch'; TargetName = 'Azure.DevOps.Repo.Branch/fixture'; Outcome = 'Pass'; OutcomeReason = 'Processed'; Reason = @() })
        $current = ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project'
        Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsAssessmentCatalog {
            $old = Get-Content "$PSScriptRoot/../src/PSRule.Rules.AzureDevOps/Assessment/catalog.json" -Raw | ConvertFrom-Json
            $old.SeverityPolicyVersion = '1.0.0'
            $old
        }
        $previous = ConvertTo-AzDevOpsAssessment $raw @() 'fixture/project'
        $comparison = Compare-AzDevOpsAssessment $previous $current
        $comparison.Comparable | Should -BeFalse
        $comparison.SecurityScoreDelta | Should -BeNullOrEmpty
    }
}
AfterAll { Remove-Module PSRule.Rules.AzureDevOps -Force }
