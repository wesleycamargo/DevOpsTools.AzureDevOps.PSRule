BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Azure service connection cloud RBAC scope' -Tag Unit {
    BeforeEach {
        $rule = 'Azure.DevOps.ServiceConnections.Scope'
        $approved = @{ Scope = '/subscriptions/synthetic/resourceGroups/approved'; RoleDefinitionId = 'synthetic-contributor' }
        $policy = @{ Reference = 'cloud-rbac-policy-v1'; ApprovedAssignments = @($approved) }
        $target = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.ServiceConnection'
            ObjectName = 'fixture.connection'
            type = 'azurerm'
            data = @{ scopeLevel = 'Subscription' }
            authorization = @{ parameters = @{ serviceprincipalid = 'synthetic-principal' } }
            CloudRbacEvidence = @{
                Status = 'Complete'
                TargetName = 'fixture.connection'
                PrincipalId = 'synthetic-principal'
                Reference = 'cloud-rbac-export-v1'
                InheritedAssignmentsIncluded = $true
                RoleDefinitionsComplete = $true
                RoleAssignments = @(@{ Scope = $approved.Scope; RoleDefinitionId = $approved.RoleDefinitionId })
            }
        }
    }

    It 'does not treat subscription selection alone as excessive RBAC' {
        (Get-AzDevOpsServiceConnectionScopeAssessment -TargetObject $target -Policy $policy).Outcome | Should -Be 'Pass'
    }
    It 'detects an unapproved broad subscription role even for a resource-group configured endpoint' {
        $target.data.scopeLevel = 'ResourceGroup'
        $target.CloudRbacEvidence.RoleAssignments[0].Scope = '/subscriptions/synthetic'
        (Get-AzDevOpsServiceConnectionScopeAssessment -TargetObject $target -Policy $policy).Outcome | Should -Be 'Fail'
    }
    It 'does not claim a pass when cloud identity or inherited assignments are unverified' {
        $target.CloudRbacEvidence.PrincipalId = 'different-identity'
        (Get-AzDevOpsServiceConnectionScopeAssessment -TargetObject $target -Policy $policy).Outcome | Should -Be 'Unknown'
        $target.CloudRbacEvidence.PrincipalId = 'synthetic-principal'
        $target.CloudRbacEvidence.InheritedAssignmentsIncluded = $false
        (Get-AzDevOpsServiceConnectionScopeAssessment -TargetObject $target -Policy $policy).Outcome | Should -Be 'Unknown'
        (Get-AzDevOpsServiceConnectionScopeAssessment -TargetObject $target -Policy $null).Outcome | Should -Be 'Unknown'
    }
    It 'evaluates using the original scope rule ID and an approved policy' {
        $config = @{ serviceConnectionScopePolicies = @{ 'Azure.DevOps.ServiceConnections.Scope' = $policy } }
        $option = New-PSRuleOption -Configuration $config
        $results = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $rule -Option $option -Culture en -ErrorAction Stop)
        $results.Count | Should -Be 1
        $results[0].Outcome | Should -Be 'Pass'
    }
    It 'reports an unassessed cloud scope as Unknown' {
        $raw = [pscustomobject]@{
            RuleName = $rule; TargetType = $target.ObjectType; TargetName = "$($target.ObjectType)/$($target.ObjectName)"
            Outcome = 'None'; OutcomeReason = ''; Reason = @()
        }
        $report = ConvertTo-AzDevOpsAssessment @($raw) @($target) 'fixture/project'
        $report.Findings[0].Outcome | Should -Be 'Unknown'
    }
}

AfterAll { Remove-Module DevOpsTools.AzureDevOps.PSRule -Force }
