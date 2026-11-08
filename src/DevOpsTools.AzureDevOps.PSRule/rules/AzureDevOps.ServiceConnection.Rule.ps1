# PSRule rule definitions for Azure DevOps Pipelines Service Connections

# Synopsis: Production service connection should be protected by one or more checks
Rule 'Azure.DevOps.ServiceConnections.ProductionCheckProtection' `
    -Ref 'ADO-SC-001' `
    -Type 'Azure.DevOps.ServiceConnection' `
    -If { ((Test-AzDevOpsProductionTarget -TargetObject $TargetObject -Configuration $Configuration).Outcome -eq 'Production') -and (Get-AzDevOpsProductionGateAssessment -TargetObject $TargetObject).Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        $assessment = Get-AzDevOpsProductionGateAssessment -TargetObject $TargetObject
        Reason $assessment.ReasonCode
        Recommend 'Configure an enabled production protection check; human approval is a separate policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.ServiceConnections.ProductionHumanApproval' `
    -Ref 'ADO-SC-002' `
    -Type 'Azure.DevOps.ServiceConnection' `
    -If { ((Test-AzDevOpsProductionTarget -TargetObject $TargetObject -Configuration $Configuration).Outcome -eq 'Production') -and (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.ServiceConnections.ProductionHumanApproval' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.ServiceConnections.ProductionHumanApproval').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Warning {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.ServiceConnections.ProductionHumanApproval' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.ServiceConnections.ProductionHumanApproval'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: service connections should have a description
Rule 'Azure.DevOps.ServiceConnections.Description' `
    -Ref 'ADO-SC-003' `
    -Type 'Azure.DevOps.ServiceConnection' `
    -Tag @{ release = 'GA'} `
    -Level Information {
        # Description 'Production service connection have a description.'
        Reason 'No description is configured for the service connection.'
        Recommend 'Add a description to the service connection to make it easier to understand its purpose.'
        $Assert.HasField($TargetObject, "description", $true)
        $Assert.HasFieldValue($TargetObject, "description")
}

# Synopsis: service connections should have a scope that is not a subscription
Rule 'Azure.DevOps.ServiceConnections.Scope' `
    -Ref 'ADO-SC-004' `
    -Type 'Azure.DevOps.ServiceConnection' `
    -Tag @{ release = 'GA'} `
    -If { $TargetObject.type -eq 'azurerm' -and (Get-AzDevOpsServiceConnectionScopeAssessment -TargetObject $TargetObject -Policy $Configuration.serviceConnectionScopePolicies.'Azure.DevOps.ServiceConnections.Scope').Outcome -ne 'Unknown' } `
    -Level Information {
        $assessment = Get-AzDevOpsServiceConnectionScopeAssessment -TargetObject $TargetObject -Policy $Configuration.serviceConnectionScopePolicies.'Azure.DevOps.ServiceConnections.Scope'
        Reason $assessment.ReasonCode
        Recommend 'Review complete Azure RBAC assignments for the service identity against the approved cloud access policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: service connections should should use Workload Idenity Federation
Rule 'Azure.DevOps.ServiceConnections.WorkloadIdentityFederation' `
    -Ref 'ADO-SC-005' `
    -Type 'Azure.DevOps.ServiceConnection' `
    -Tag @{ release = 'GA'} `
    -If { $TargetObject.data.scopeLevel -eq 'Subscription' -and $TargetObject.type -eq 'azurerm' } `
    -Level Warning {
        # Description 'Service connection should should use Workload Idenity Federation.'
        Reason 'The service connection does not use Workload Idenity Federation.'
        Recommend 'Use Workload Idenity Federation to authenticate the service connection.'
        # Links 'https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops#create-an-azure-resource-manager-service-connection-using-workload-identity-federation'
        AllOf {
            $Assert.HasField($TargetObject, "data.scopeLevel", $true)
            $Assert.HasField($TargetObject, "authorization.parameters.workloadIdentityFederationSubject", $true)
        }
}

# Synopsis: Production service connection should be limited to specific branches
Rule 'Azure.DevOps.ServiceConnections.ProductionBranchLimit' `
    -Ref 'ADO-SC-006' `
    -Type 'Azure.DevOps.ServiceConnection' `
    -If { ((Test-AzDevOpsProductionTarget -TargetObject $TargetObject -Configuration $Configuration).Outcome -eq 'Production') -and (Get-AzDevOpsProductionBranchAssessment -TargetObject $TargetObject).Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        $assessment = Get-AzDevOpsProductionBranchAssessment -TargetObject $TargetObject
        Reason $assessment.ReasonCode
        Recommend 'Configure an enabled branch-control check with restricted allowed branches.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: Service Connection should not be of the classic azure type
Rule 'Azure.DevOps.ServiceConnections.ClassicAzure' `
    -Ref 'ADO-SC-007' `
    -Type 'Azure.DevOps.ServiceConnection' `
    -Tag @{ release = 'GA'} `
    -If { $TargetObject.type -match 'azure' } `
    -Level Warning {
        # Description 'Service Connection should not be of the classic azure type.'
        Reason 'The service connection is of the classic azure type.'
        Recommend 'Use the Azure Resource Manager service connection type.'
        $Assert.NotIn($TargetObject, "type", "azure")
}

# Synposis: Service Connections of the GitHub type should not use a PAT
Rule 'Azure.DevOps.ServiceConnections.GitHubPAT' `
    -Ref 'ADO-SC-008' `
    -Type 'Azure.DevOps.ServiceConnection' `
    -If { $TargetObject.type -match 'github' } `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description 'Service Connections of the GitHub type should not use a PAT.'
        Reason 'The service connection uses a PAT.'
        Recommend 'Use a GitHub App instead of a PAT.'
        $Assert.NotIn($TargetObject, "authorization.scheme", "Token")
}

# Synposis: Service Connections should not inherit permissions
Rule 'Azure.DevOps.ServiceConnections.InheritedPermissions' `
    -Ref 'ADO-SC-009' `
    -Type 'Azure.DevOps.ServiceConnection' `
    -If { (Get-AzDevOpsEffectivePermissionAssessment -Evidence $TargetObject.PermissionEvidence -Policy $Configuration.effectivePermissionPolicies.'Azure.DevOps.ServiceConnection').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA'; assessment = 'EffectivePermissions'; legacyName = 'InheritedPermissions' } `
    -Level Warning {
        $assessment = Get-AzDevOpsEffectivePermissionAssessment -Evidence $TargetObject.PermissionEvidence -Policy $Configuration.effectivePermissionPolicies.'Azure.DevOps.ServiceConnection'
        Reason $assessment.ReasonCode
        Recommend 'Restrict unauthorized effective privileges or update the approved permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synposis: Service connections should not have direct permissions for Project Valid Users
Rule 'Azure.DevOps.ServiceConnections.ProjectValidUsers' `
    -Ref 'ADO-SC-010' `
    -Type 'Azure.DevOps.ServiceConnection' `
    -If { (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.ServiceConnections.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.ServiceConnections.ProjectValidUsers').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        $assessment = Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.ServiceConnections.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.ServiceConnections.ProjectValidUsers'
        Reason $assessment.ReasonCode
        Recommend 'Review unauthorized sensitive Project Valid Users grants using a documented namespace-specific permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}
