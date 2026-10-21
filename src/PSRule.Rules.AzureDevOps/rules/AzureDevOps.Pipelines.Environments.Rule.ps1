# PSRule rule definitions for Azure DevOps Pipelines Environments

# Synopsis: Production environment should be protected by one or more checks
Rule 'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection' `
    -Ref 'ADO-E-001' `
    -Type 'Azure.DevOps.Pipelines.Environment' `
    -If { (Get-AzDevOpsProductionGateAssessment -TargetObject $TargetObject).Outcome -ne 'Unknown' } `
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
    -If { (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Pipelines.Environments.ProductionHumanApproval' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Pipelines.Environments.ProductionHumanApproval').Outcome -in @('Pass', 'Fail') } `
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
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description 'Production environment should be limited to specific branches'
        Reason 'The environment is not limited to specific branches'
        Recommend 'Limit the environment to specific branches'
        # Links 'https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops#check-gates'
        $Assert.HasField($TargetObject, "checks[?@settings.displayName == 'Branch control'].settings.inputs.allowedBranches", $true)
        $Assert.HasFieldValue($TargetObject, "checks[?@settings.displayName == 'Branch control'].settings.inputs.allowedBranches")
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
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description 'Environments should not have direct permissions for Project Valid Users.'
        Reason 'The environment has direct permissions for Project Valid Users.'
        Recommend 'Do not grant direct permissions for Project Valid Users for the environment.'        
        AllOf {
            # Loop through all the propeties of the first ACL
            $TargetObject.Acls[0].acesDictionary.psobject.Properties.GetEnumerator() | ForEach-Object {
                # Assert the property name does not end with -0-0-0-0-3 wich is the Project Valid Users group SID
                AnyOf {
                    $Assert.NotMatch($_.Value, "descriptor", "-0-0-0-0-3")
                    $Assert.HasFieldValue($_.Value, "allow", 1)
                }
            }
        }
}
