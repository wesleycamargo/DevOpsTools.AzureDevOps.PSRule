# PSRule rule definitions for Azure DevOps Retention Settings

# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays' `
    -Ref 'ADO-RET-001' `
    -Type 'Azure.DevOps.RetentionSettings' `
    -If { (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Warning {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays' `
    -Ref 'ADO-RET-002' `
    -Type 'Azure.DevOps.RetentionSettings' `
    -If { (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Warning {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}