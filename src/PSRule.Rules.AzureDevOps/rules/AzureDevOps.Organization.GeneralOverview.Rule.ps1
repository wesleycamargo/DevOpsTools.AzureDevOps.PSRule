# Azure DevOps organization General Overview settings rules

# Synopsis: Organization description should be set
Rule 'Azure.DevOps.Organization.GeneralOverview.DescriptionSet' `
    -Ref 'ADO-OGO-001' `
    -Type 'Azure.DevOps.Organization.GeneralOverview' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Setting an organization description helps provide context and clarity for the organization's purpose.
        Reason 'The organization description is not set.'
        Recommend 'Set a meaningful description in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/settings/organization-overview?view=azure-devops
        $Assert.HasField($TargetObject, "description", $true)
        $Assert.HasFieldValue($TargetObject, "description", "Not Set") -eq $false
}

# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.Organization.GeneralOverview.TimeZoneSet' `
    -Ref 'ADO-OGO-002' `
    -Type 'Azure.DevOps.Organization.GeneralOverview' `
    -If { (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Organization.GeneralOverview.TimeZoneSet' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Organization.GeneralOverview.TimeZoneSet').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Error {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Organization.GeneralOverview.TimeZoneSet' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Organization.GeneralOverview.TimeZoneSet'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.Organization.GeneralOverview.GeographySet' `
    -Ref 'ADO-OGO-003' `
    -Type 'Azure.DevOps.Organization.GeneralOverview' `
    -If { (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Organization.GeneralOverview.GeographySet' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Organization.GeneralOverview.GeographySet').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Error {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Organization.GeneralOverview.GeographySet' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Organization.GeneralOverview.GeographySet'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: Organization owner should be set
Rule 'Azure.DevOps.Organization.GeneralOverview.OwnerSet' `
    -Ref 'ADO-OGO-004' `
    -Type 'Azure.DevOps.Organization.GeneralOverview' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Setting the organization owner ensures accountability and proper management of the organization.
        Reason 'The organization owner is not set.'
        Recommend 'Set an owner in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/settings/organization-overview?view=azure-devops
        $Assert.HasField($TargetObject, "owner", $true)
        $Assert.HasFieldValue($TargetObject, "owner")
}