# PSRule rule definitions for Azure DevOps Pipelines definitions

# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.Project.Visibility' `
    -Ref 'ADO-PRJ-001' `
    -Type 'Azure.DevOps.Project' `
    -If { (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.Visibility' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Project.Visibility').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Warning {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.Visibility' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Project.Visibility'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synposis: Project level pipeline acl should not have custom permissions for Project Valid Users
Rule 'Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers' `
    -Ref 'ADO-PRJ-002' `
    -Type 'Azure.DevOps.Project' `
    -If { (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        $assessment = Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers'
        Reason $assessment.ReasonCode
        Recommend 'Review unauthorized sensitive Project Valid Users grants using a documented namespace-specific permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synposis: Project level service connection acl should not have custom permissions for Project Valid Users
Rule 'Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers' `
    -Ref 'ADO-PRJ-003' `
    -Type 'Azure.DevOps.Project' `
    -If { (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        $assessment = Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers'
        Reason $assessment.ReasonCode
        Recommend 'Review unauthorized sensitive Project Valid Users grants using a documented namespace-specific permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synposis: Project level repositories acl should not have custom permissions for Project Valid Users
Rule 'Azure.DevOps.Project.MainRepositoryAcl.ProjectValidUsers' `
    -Ref 'ADO-PRJ-004' `
    -Type 'Azure.DevOps.Project' `
    -If { (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.MainRepositoryAcl.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Project.MainRepositoryAcl.ProjectValidUsers').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        $assessment = Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.MainRepositoryAcl.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Project.MainRepositoryAcl.ProjectValidUsers'
        Reason $assessment.ReasonCode
        Recommend 'Review unauthorized sensitive Project Valid Users grants using a documented namespace-specific permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synposis: Project level environments acl should not have custom permissions for Project Valid Users
Rule 'Azure.DevOps.Project.MainEnvironmentAcl.ProjectValidUsers' `
    -Ref 'ADO-PRJ-005' `
    -Type 'Azure.DevOps.Project' `
    -If { (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.MainEnvironmentAcl.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Project.MainEnvironmentAcl.ProjectValidUsers').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        $assessment = Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.MainEnvironmentAcl.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Project.MainEnvironmentAcl.ProjectValidUsers'
        Reason $assessment.ReasonCode
        Recommend 'Review unauthorized sensitive Project Valid Users grants using a documented namespace-specific permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synposis: Project level release definitions acl should not have custom permissions for Project Valid Users
Rule 'Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers' `
    -Ref 'ADO-PRJ-006' `
    -Type 'Azure.DevOps.Project' `
    -If { (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        $assessment = Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers'
        Reason $assessment.ReasonCode
        Recommend 'Review unauthorized sensitive Project Valid Users grants using a documented namespace-specific permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synposis: Project level variable groups acl should not have custom permissions for Project Valid Users
Rule 'Azure.DevOps.Project.MainVariableGroupAcl.ProjectValidUsers' `
    -Ref 'ADO-PRJ-007' `
    -Type 'Azure.DevOps.Project' `
    -If { (Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.MainVariableGroupAcl.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Project.MainVariableGroupAcl.ProjectValidUsers').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        $assessment = Get-AzDevOpsProjectValidUsersAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Project.MainVariableGroupAcl.ProjectValidUsers' -Policy $Configuration.projectValidUsersPolicies.'Azure.DevOps.Project.MainVariableGroupAcl.ProjectValidUsers'
        Reason $assessment.ReasonCode
        Recommend 'Review unauthorized sensitive Project Valid Users grants using a documented namespace-specific permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}