BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.Assessment/DevOpsTools.AzureDevOps.Assessment.psd1" -Force
}
Describe 'Production protection diagnostics' -Tag 'Unit' {
    It 'distinguishes missing, disabled, configured, and unavailable gates' {
        (Get-AzDevOpsProductionGateAssessment @{ Checks = @() }).ReasonCode | Should -Be 'MissingProductionGate'
        (Get-AzDevOpsProductionGateAssessment @{ Checks = @(@{ isDisabled = $true }) }).ReasonCode | Should -Be 'DisabledProductionGate'
        (Get-AzDevOpsProductionGateAssessment @{ Checks = @(@{ type = @{ name = 'InvokeRESTAPI' }; settings = @{ inputs = @{ definition = 'synthetic-reviewed-gate' } } }) }).Outcome | Should -Be 'Pass'
        (Get-AzDevOpsProductionGateAssessment @{ Checks = @(@{ type = @{ name = 'Approval' }; settings = @{ approvers = @() } }) }).Outcome | Should -Be 'Fail'
        (Get-AzDevOpsProductionGateAssessment @{ Checks = @(@{ type = @{ name = 'InvokeRESTAPI' }; settings = @{} }) }).Outcome | Should -Be 'Unknown'
        (Get-AzDevOpsProductionGateAssessment @{}).Outcome | Should -Be 'Unknown'
        (Get-AzDevOpsProductionGateAssessment @{ Checks = @(@{ type = @{ name = 'InvokeRESTAPI' } }) }).Outcome | Should -Be 'Unknown'
    }
    It 'keeps automated protection separate from mandatory human review for both target types' {
        $targets = @(
            [pscustomobject]@{ ObjectType = 'Azure.DevOps.Pipelines.Environment'; ObjectName = 'environment'; name = 'production'; Checks = @(@{ type = @{ name = 'InvokeRESTAPI' }; settings = @{ inputs = @{ definition = 'synthetic-reviewed-gate' } } }) }
            [pscustomobject]@{ ObjectType = 'Azure.DevOps.ServiceConnection'; ObjectName = 'connection'; name = 'production'; Checks = @(@{ type = @{ name = 'InvokeRESTAPI' }; settings = @{ inputs = @{ definition = 'synthetic-reviewed-gate' } } }) }
        )
        $configuration = @{ assessmentPolicies = @{
            'Azure.DevOps.Pipelines.Environments.ProductionHumanApproval' = @{ Reference = 'production-review-v1' }
            'Azure.DevOps.ServiceConnections.ProductionHumanApproval' = @{ Reference = 'production-review-v1' }
        } }
        $option = New-PSRuleOption -Configuration $configuration
        $rules = @('Azure.DevOps.Pipelines.Environments.ProductionCheckProtection', 'Azure.DevOps.Pipelines.Environments.ProductionHumanApproval', 'Azure.DevOps.ServiceConnections.ProductionCheckProtection', 'Azure.DevOps.ServiceConnections.ProductionHumanApproval')
        $raw = @($targets | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name $rules -Option $option -Outcome All -Culture en -ErrorAction Stop)
        $report = ConvertTo-AzDevOpsAssessment $raw $targets 'fixture/project' -Configuration $configuration
        @($report.Findings | Where-Object { $_.RuleId -like '*.ProductionCheckProtection' -and $_.Outcome -eq 'Pass' }).Count | Should -Be 2
        @($report.Findings | Where-Object { $_.RuleId -like '*.ProductionHumanApproval' -and $_.Outcome -eq 'Fail' }).Count | Should -Be 2
        $report.RiskObjectives.Count | Should -Be 4
    }
}
AfterAll { Remove-Module DevOpsTools.AzureDevOps.Assessment -Force }
