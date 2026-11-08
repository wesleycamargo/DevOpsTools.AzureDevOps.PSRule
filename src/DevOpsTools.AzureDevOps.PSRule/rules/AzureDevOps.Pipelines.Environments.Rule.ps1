# PSRule rule definitions for Azure DevOps Pipelines Environments

# Synopsis: Production environment should be protected by one or more checks
Rule 'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection' `
    -Ref 'ADO-E-001' `
    -Type 'Azure.DevOps.Pipelines.Environment' `
    -If { ((Test-AzDevOpsProductionTarget -TargetObject $TargetObject -Configuration $Configuration).Outcome -eq 'Production') -and (Get-AzDevOpsProductionGateAssessment -TargetObject $TargetObject).Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        $assessment = Get-AzDevOpsProductionGateAssessment -TargetObject $TargetObject
        Reason $assessment.ReasonCode
        Recommend 'Configure an enabled production protection check; human approval is a separate policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.Pipelines.Environments.ProductionHumanApproval' `
    -Ref 'ADO-E-002' `
    -Type 'Azure.DevOps.Pipelines.Environment' `
    -If { ((Test-AzDevOpsProductionTarget -TargetObject $TargetObject -Configuration $Configuration).Outcome -eq 'Production') -and (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Pipelines.Environments.ProductionHumanApproval' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Pipelines.Environments.ProductionHumanApproval').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Warning {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Pipelines.Environments.ProductionHumanApproval' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Pipelines.Environments.ProductionHumanApproval'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: Environments should have a description
Rule 'Azure.DevOps.Pipelines.Environments.Description' `
    -Ref 'ADO-E-003' `
    -Type 'Azure.DevOps.Pipelines.Environment' `
    -Tag @{ release = 'GA'} `
    -Level Information {
        # Description 'Production environment have a description'
        Reason 'No description is configured for the environment'
        Recommend 'Add a description to the environment to make it easier to understand its purpose'
        # Links 'https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops#check-gates'
        $Assert.HasField($TargetObject, "description", $true)
        $Assert.HasFieldValue($TargetObject, "description")
}

# Synopsis: Production environment should be limited to specific branches
Rule 'Azure.DevOps.Pipelines.Environments.ProductionBranchLimit' `
    -Ref 'ADO-E-004' `
    -Type 'Azure.DevOps.Pipelines.Environment' `
    -If { ((Test-AzDevOpsProductionTarget -TargetObject $TargetObject -Configuration $Configuration).Outcome -eq 'Production') -and (Get-AzDevOpsProductionBranchAssessment -TargetObject $TargetObject).Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        $assessment = Get-AzDevOpsProductionBranchAssessment -TargetObject $TargetObject
        Reason $assessment.ReasonCode
        Recommend 'Configure an enabled branch-control check with restricted allowed branches.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: Effective environment privileges must be authorized
Rule 'Azure.DevOps.Pipelines.Environments.InheritedPermissions' `
    -Ref 'ADO-E-005' `
    -Type 'Azure.DevOps.Pipelines.Environment' `
    -If { (Get-AzDevOpsEffectivePermissionAssessment -Evidence $TargetObject.PermissionEvidence -Policy $Configuration.effectivePermissionPolicies.'Azure.DevOps.Pipelines.Environment').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA'; assessment = 'EffectivePermissions'; legacyName = 'InheritedPermissions' } `
    -Level Warning {
        $assessment = Get-AzDevOpsEffectivePermissionAssessment -Evidence $TargetObject.PermissionEvidence -Policy $Configuration.effectivePermissionPolicies.'Azure.DevOps.Pipelines.Environment'
        Reason $assessment.ReasonCode
        Recommend 'Restrict unauthorized effective privileges or update the approved permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synposis: Environments should not have direct permissions for Project Valid Users
Rule 'Azure.DevOps.Pipelines.Environments.ProjectValidUsers' `
    -Ref 'ADO-E-006' `
    -Type 'Azure.DevOps.Pipelines.Environment' `
    -If { (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Pipelines.Environments.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Pipelines.Environments.ProjectValidUsers').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        $assessment = Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Pipelines.Environments.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Pipelines.Environments.ProjectValidUsers'
        Reason $assessment.ReasonCode
        Recommend 'Review unauthorized sensitive Project Valid Users grants using a documented namespace-specific permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}
