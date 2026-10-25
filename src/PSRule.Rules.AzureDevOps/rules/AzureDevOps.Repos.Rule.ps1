# PSRule rule definitions for Azure DevOps Repos

# Synopsis: The default branch should have a branch policy
Rule 'Azure.DevOps.Repos.HasDefaultBranchPolicy' `
    -Ref 'ADO-RP-001' `
    -Type 'Azure.DevOps.Repo' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description: The default branch should have a branch policy
        Reason 'The default branch does not have a branch policy.'
        Recommend 'Protect your main branch with a branch policy.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#secure-azure-repos
        $Assert.HasField($TargetObject, "MainBranchPolicy", $true)
        $Assert.NotNull($TargetObject, "MainBranchPolicy")
}

# Synopsis: The default branch should have its branch policy enabled
Rule 'Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled' `
    -Ref 'ADO-RP-001a' `
    -Type 'Azure.DevOps.Repo' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description: The default branch should have its branch policy enabled
        Reason 'The default branch does not have its branch policy enabled.'
        Recommend 'Protect your main branch with a branch policy.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#secure-azure-repos
        $Assert.HasField(($TargetObject.MainBranchPolicy | Where-Object { $_.isEnabled } | Select-Object -First 1), "isEnabled", $true)
        $Assert.HasFieldValue(($TargetObject.MainBranchPolicy | Where-Object { $_.isEnabled } | Select-Object -First 1), "isEnabled", $true)
}


# Synopsis: The default branch policy should require a minimum number of reviewers
Rule 'Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers' `
    -Ref 'ADO-RP-002' `
    -Type 'Azure.DevOps.Repo' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description: The default branch policy should require a minimum number of reviewers
        Reason 'The default branch policy does not require any reviewers.'
        Recommend 'Require a minimum number of reviewers to approve pull requests.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#repositories-and-branches
        $policies = @($TargetObject.MainBranchPolicy | Where-Object { $_.type.id -eq 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' -and $_.isEnabled -eq $true -and $_.isBlocking -eq $true -and $null -ne $_.settings.minimumApproverCount -and $_.settings.minimumApproverCount -ge $Configuration.GetValueOrDefault('branchMinimumApproverCount', 1) })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The default branch policy should not allow creators to approve their own changes
Rule 'Azure.DevOps.Repos.DefaultBranchPolicyAllowSelfApproval' `
    -Ref 'ADO-RP-003' `
    -Type 'Azure.DevOps.Repo' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description: The default branch policy should not allow creators to approve their own changes
        Reason 'The default branch policy allows creators to approve their own changes.'
        Recommend 'Do not allow users to approve their own changes.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#policies
        $policies = @($TargetObject.MainBranchPolicy | Where-Object { $_.type.id -eq 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' -and $_.isEnabled -eq $true -and $_.isBlocking -eq $true -and $_.settings.creatorVoteCounts -eq $false })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The default branch policy should reset code reviewer votes when new changes are pushed
Rule 'Azure.DevOps.Repos.DefaultBranchPolicyResetVotes' `
    -Ref 'ADO-RP-004' `
    -Type 'Azure.DevOps.Repo' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description: The default branch policy should reset code reviewer votes when new changes are pushed
        Reason 'The default branch policy does not reset code reviewer votes when new changes are pushed.'
        Recommend 'Reset code reviewer votes when new changes are pushed.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#policies
        $policies = @($TargetObject.MainBranchPolicy | Where-Object { $_.type.id -eq 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' -and $_.isEnabled -eq $true -and $_.isBlocking -eq $true -and $_.settings.resetOnSourcePush -eq $true })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The repository should contain a README file
Rule 'Azure.DevOps.Repos.Readme' `
    -Ref 'ADO-RP-005' `
    -Type 'Azure.DevOps.Repo' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description: The repository should contain a README file
        Reason 'The repository does not contain a README or README.md file.'
        Recommend 'Add a README or README.md file to the repository to explain its purpose.'
        $Assert.HasField($TargetObject, "ReadmeExists", $true)
        $Assert.HasFieldValue($TargetObject, "ReadmeExists", $true)
}

# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.Repos.License' `
    -Ref 'ADO-RP-006' `
    -Type 'Azure.DevOps.Repo' `
    -If { (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Repos.License' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Repos.License').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Warning {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Repos.License' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Repos.License'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: The default branch policy enforce linked work items
Rule 'Azure.DevOps.Repos.DefaultBranchPolicyEnforceLinkedWorkItems' `
    -Ref 'ADO-RP-007' `
    -Type 'Azure.DevOps.Repo' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description 'The default branch policy enforce linked work items.'
        Reason 'The default branch policy does not enforce linked work items.'
        Recommend 'Enforce linked work items.'
        # Links 'https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#enforce-linked-work-items'
        $policies = @($TargetObject.MainBranchPolicy | Where-Object { $_.type.id -eq '40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e' -and $_.isEnabled -eq $true -and $_.isBlocking -eq $true })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The default branch policy should enforce comment resolution
Rule 'Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution' `
    -Ref 'ADO-RP-008' `
    -Type 'Azure.DevOps.Repo' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description 'The default branch policy should enforce comment resolution'
        Reason 'The default branch policy does not enforce comment resolution'
        Recommend 'Enforce comment resolution'
        # Links 'https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#enforce-comment-resolution'
        $policies = @($TargetObject.MainBranchPolicy | Where-Object { $_.type.id -eq 'c6a1889d-b943-4856-b76f-9e46bb6b0df2' -and $_.isEnabled -eq $true -and $_.isBlocking -eq $true })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The default branch policy should require a merge strategy
Rule 'Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy' `
    -Ref 'ADO-RP-009' `
    -Type 'Azure.DevOps.Repo' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description 'The default branch policy should require a merge strategy'
        Reason 'The default branch policy does not require a merge strategy'
        Recommend 'Consider requiring a merge strategy'
        # Links 'https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#require-a-merge-strategy'
        $policies = @($TargetObject.MainBranchPolicy | Where-Object { $_.type.id -eq 'fa4e907d-c16b-4a4c-9dfa-4916e5d171ab' -and $_.isEnabled -eq $true -and $_.isBlocking -eq $true -and ($_.settings.allowSquash -eq $true -or $_.settings.allowRebase -eq $true -or $_.settings.allowNoFastForward -eq $true -or $_.settings.allowRebaseMerge -eq $true) })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled' `
    -Ref 'ADO-RP-010' `
    -Type 'Azure.DevOps.Repo' `
    -If { (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Warning {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes' `
    -Ref 'ADO-RP-011' `
    -Type 'Azure.DevOps.Repo' `
    -If { (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Warning {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: Effective repository privileges must be authorized
Rule 'Azure.DevOps.Repos.InheritedPermissions' `
    -Ref 'ADO-RP-012' `
    -Type 'Azure.DevOps.Repo' `
    -If { (Get-AzDevOpsEffectivePermissionAssessment -Evidence $TargetObject.PermissionEvidence -Policy $Configuration.effectivePermissionPolicies.'Azure.DevOps.Repo').Outcome -ne 'Unknown' } `
    -Tag @{ release = 'GA'; assessment = 'EffectivePermissions'; legacyName = 'InheritedPermissions' } `
    -Level Warning {
        $assessment = Get-AzDevOpsEffectivePermissionAssessment -Evidence $TargetObject.PermissionEvidence -Policy $Configuration.effectivePermissionPolicies.'Azure.DevOps.Repo'
        Reason $assessment.ReasonCode
        Recommend 'Restrict unauthorized effective privileges or update the approved permission policy.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: The default branch policy should require a build/pipeline to pass
Rule 'Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild' `
    -Ref 'ADO-RP-013' `
    -Type 'Azure.DevOps.Repo' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description 'The default branch policy should require a build/pipeline to pass'
        Reason 'The default branch policy does not require a build/pipeline to pass'
        Recommend 'Consider requiring a build/pipeline to pass'
        # Links 'https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops'
        $policies = @($TargetObject.MainBranchPolicy | Where-Object { $_.type.id -eq '0609b952-1397-4640-95ec-e00a01b2c241' -and $_.isEnabled -eq $true -and $_.isBlocking -eq $true -and $_.settings.buildDefinitionId -gt 0 })
        $Assert.Greater($policies, 'Count', 0)
}

# Synposis: Repos should not have direct permissions for Project Valid Users
Rule 'Azure.DevOps.Repos.ProjectValidUsers' `
    -Ref 'ADO-RP-014' `
    -Type 'Azure.DevOps.Repo' `
    -If { $null -ne $TargetObject.Acls } `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description 'Repos should not have direct permissions for Project Valid Users.'
        Reason 'The repository has direct permissions for Project Valid Users.'
        Recommend 'Do not grant direct permissions for Project Valid Users for the repository.'
        AllOf {
            # Loop through all the properties of the first ACL
            $TargetObject.Acls.acesDictionary.psobject.Properties.GetEnumerator() | ForEach-Object {
                # Assert the property name does not end with -0-0-0-0-3 wich is the Project Valid Users group SID
                # or else does not have allow set to something different than 1
                AnyOf {
                    $Assert.NotMatch($_.Value, "descriptor", "-0-0-0-0-3")
                    $Assert.HasFieldValue($_.Value, "allow", 2)
                }
            }
        }
}

