# PSRule rule definitions for Azure DevOps Variable Groups

# Synopsis: Deprecated alias for evidence-based variable group secret handling
Rule 'Azure.DevOps.Tasks.VariableGroup.NoKeyVaultNoSecrets' `
    -Ref 'ADO-VG-001' `
    -Type 'Azure.DevOps.Tasks.VariableGroup' `
    -If { (Get-AzDevOpsVariableGroupSecretAssessment -TargetObject $TargetObject).Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA'; riskGroup = 'VariableGroup.SecretExposure'; deprecated = 'true'; replacement = 'Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets' } `
    -Level Error {
        $assessment = Get-AzDevOpsVariableGroupSecretAssessment -TargetObject $TargetObject
        Reason $assessment.ReasonCode
        Recommend 'Mask secret variables or use a Key Vault reference. Rotate exposed credentials.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: Variable groups should have a description
Rule 'Azure.DevOps.Tasks.VariableGroup.Description' `
    -Ref 'ADO-VG-002' `
    -Type 'Azure.DevOps.Tasks.VariableGroup' `
    -Tag @{ release = 'GA'} `
    -Level Information {
        # Description 'Variable groups should have a description.'
        Reason 'No description is configured for the variable group.'
        Recommend 'Add a description to the variable group to make it easier to understand its purpose.'
        $Assert.HasField($TargetObject, "description", $true)
        $Assert.HasFieldValue($TargetObject, "description")
}

# Synopsis: Variable groups should not contain plain text secrets
Rule 'Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets' `
    -Ref 'ADO-VG-003' `
    -Type 'Azure.DevOps.Tasks.VariableGroup' `
    -If { (Get-AzDevOpsVariableGroupSecretAssessment -TargetObject $TargetObject).Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA'; riskGroup = 'VariableGroup.SecretExposure' } `
    -Level Error {
        $assessment = Get-AzDevOpsVariableGroupSecretAssessment -TargetObject $TargetObject
        Reason $assessment.ReasonCode
        Recommend 'Mask secret variables or use a Key Vault reference. Rotate exposed credentials.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: Effective variable group privileges must be authorized
Rule 'Azure.DevOps.Tasks.VariableGroup.InheritedPermissions' `
    -Ref 'ADO-VG-004' `
    -Type 'Azure.DevOps.Tasks.VariableGroup' `
    -If { (Get-AzDevOpsEffectivePermissionAssessment -Evidence $TargetObject.PermissionEvidence -Policy $Configuration.effectivePermissionPolicies.'Azure.DevOps.Tasks.VariableGroup').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA'; assessment = 'EffectivePermissions'; legacyName = 'InheritedPermissions' } `
    -Level Warning {
        $assessment = Get-AzDevOpsEffectivePermissionAssessment -Evidence $TargetObject.PermissionEvidence -Policy $Configuration.effectivePermissionPolicies.'Azure.DevOps.Tasks.VariableGroup'
        Reason $assessment.ReasonCode
        Recommend 'Restrict unauthorized effective privileges or update the approved permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synposis: Variable groups should not have direct permissions for Project Valid Users
Rule 'Azure.DevOps.Tasks.VariableGroup.ProjectValidUsers' `
    -Ref 'ADO-VG-005' `
    -Type 'Azure.DevOps.Tasks.VariableGroup' `
    -If { (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Tasks.VariableGroup.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Tasks.VariableGroup.ProjectValidUsers').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        $assessment = Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Tasks.VariableGroup.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Tasks.VariableGroup.ProjectValidUsers'
        Reason $assessment.ReasonCode
        Recommend 'Review unauthorized sensitive Project Valid Users grants using a documented namespace-specific permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}
