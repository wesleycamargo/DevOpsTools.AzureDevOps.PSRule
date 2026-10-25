# Azure DevOps organization General Billing Settings rules

# Synopsis: Subscription status should be active
Rule 'Azure.DevOps.Organization.GeneralBillingSettings.SubscriptionActive' `
    -Ref 'ADO-OGB-001' `
    -Type 'Azure.DevOps.Organization.GeneralBillingSettings' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: An active subscription ensures uninterrupted access to Azure DevOps services.
        Reason 'The subscription status is not set to active.'
        Recommend 'Ensure the Azure DevOps organization subscription is active in the billing settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/billing/overview
        $Assert.HasField($TargetObject, "subscriptionStatus", $true)
        $Assert.HasFieldValue($TargetObject, "subscriptionStatus", "active")
}

# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured' `
    -Ref 'ADO-OGB-002' `
    -Type 'Azure.DevOps.Organization.GeneralBillingSettings' `
    -If { (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Warning {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled' `
    -Ref 'ADO-OGB-003' `
    -Type 'Azure.DevOps.Organization.GeneralBillingSettings' `
    -If { (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Error {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}