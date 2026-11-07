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
            authorization = @{ parameters = @{
                serviceprincipalid = '11111111-1111-4111-8111-111111111111'
                tenantid = '33333333-3333-4333-8333-333333333333'
            } }
            CloudRbacEvidence = @{
                Status = 'Complete'
                TargetName = 'fixture.connection'
                PrincipalId = '22222222-2222-4222-8222-222222222222'
                IdentityVerified = $true
                Reference = 'cloud-rbac-export-v1'
                IdentityMapping = @{
                    ApplicationId = '11111111-1111-4111-8111-111111111111'
                    PrincipalId = '22222222-2222-4222-8222-222222222222'
                    TenantId = '33333333-3333-4333-8333-333333333333'
                    Verified = $true
                    Reference = 'tenant-service-principal-lookup-v1'
                }
                InheritedAssignmentsIncluded = $true
                RoleDefinitionsComplete = $true
                RoleAssignments = @(@{ Scope = $approved.Scope; RoleDefinitionId = $approved.RoleDefinitionId })
            }
        }
    }

    It 'accepts a verified mapping between distinct application and object IDs' {
        $target.authorization.parameters.serviceprincipalid | Should -Not -Be $target.CloudRbacEvidence.PrincipalId
        $assessment = Get-AzDevOpsServiceConnectionScopeAssessment -TargetObject $target -Policy $policy
        $assessment.Outcome | Should -Be 'Pass'
        $assessment.ReasonCode | Should -Be 'CloudRbacAssignmentsApproved'
    }

    It 'rejects equal legacy IDs without a verified mapping' {
        $target.CloudRbacEvidence.PrincipalId = $target.authorization.parameters.serviceprincipalid
        $target.CloudRbacEvidence.Remove('IdentityMapping')
        (Get-AzDevOpsServiceConnectionScopeAssessment -TargetObject $target -Policy $policy).Outcome | Should -Be 'Unknown'
    }

    It 'returns Unknown for <Case> identity evidence' -ForEach @(
        @{ Case = 'missing mapping'; Change = { param($t) $t.CloudRbacEvidence.Remove('IdentityMapping') } }
        @{ Case = 'unverified mapping'; Change = { param($t) $t.CloudRbacEvidence.IdentityMapping.Verified = $false } }
        @{ Case = 'string verification flag'; Change = { param($t) $t.CloudRbacEvidence.IdentityMapping.Verified = 'true' } }
        @{ Case = 'missing mapping reference'; Change = { param($t) $t.CloudRbacEvidence.IdentityMapping.Reference = ' ' } }
        @{ Case = 'wrong application'; Change = { param($t) $t.CloudRbacEvidence.IdentityMapping.ApplicationId = '44444444-4444-4444-8444-444444444444' } }
        @{ Case = 'wrong object'; Change = { param($t) $t.CloudRbacEvidence.IdentityMapping.PrincipalId = '44444444-4444-4444-8444-444444444444' } }
        @{ Case = 'wrong tenant'; Change = { param($t) $t.CloudRbacEvidence.IdentityMapping.TenantId = '44444444-4444-4444-8444-444444444444' } }
        @{ Case = 'missing endpoint application'; Change = { param($t) $t.authorization.parameters.Remove('serviceprincipalid') } }
        @{ Case = 'missing endpoint tenant'; Change = { param($t) $t.authorization.parameters.Remove('tenantid') } }
        @{ Case = 'malformed object'; Change = { param($t) $t.CloudRbacEvidence.PrincipalId = 'not-an-object-id' } }
        @{ Case = 'empty mapping object'; Change = { param($t) $t.CloudRbacEvidence.IdentityMapping.PrincipalId = '00000000-0000-0000-0000-000000000000' } }
        @{ Case = 'string top-level verification'; Change = { param($t) $t.CloudRbacEvidence.IdentityVerified = 'true' } }
        @{ Case = 'wrong target'; Change = { param($t) $t.CloudRbacEvidence.TargetName = 'fixture.other' } }
        @{ Case = 'incomplete role definitions'; Change = { param($t) $t.CloudRbacEvidence.RoleDefinitionsComplete = $false } }
    ) {
        & $Change $target
        $assessment = Get-AzDevOpsServiceConnectionScopeAssessment -TargetObject $target -Policy $policy
        $assessment.Outcome | Should -Be 'Unknown'
        $assessment.ReasonCode | Should -Be 'CloudRbacEvidenceUnavailable'
    }

    It 'keeps a missing identity mapping Unknown through PSRule and projection' {
        $target.CloudRbacEvidence.Remove('IdentityMapping')
        $configuration = @{ serviceConnectionScopePolicies = @{ $rule = $policy } }
        $option = New-PSRuleOption -Configuration $configuration
        $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule `
            -Name $rule -Option $option -Outcome All -Culture en -ErrorAction Stop)
        $raw.Count | Should -Be 1
        $raw[0].Outcome | Should -Be 'None'
        $report = ConvertTo-AzDevOpsAssessment $raw @($target) 'fixture/project' -Configuration $configuration
        $report.Findings[0].Outcome | Should -Be 'Unknown'
        $report.Summary.SecurityScore | Should -BeNullOrEmpty
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
        $target.CloudRbacEvidence.PrincipalId = '22222222-2222-4222-8222-222222222222'
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
