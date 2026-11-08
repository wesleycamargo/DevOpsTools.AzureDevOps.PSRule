# PSRule rule definitions for Azure DevOps Repo Branches

# Synopsis: The branch should have a branch policy
Rule 'Azure.DevOps.Repos.Branch.HasBranchPolicy' `
    -Ref 'ADO-RB-001' `
    -Type 'Azure.DevOps.Repo.Branch' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description: The default branch should have a branch policy
        Reason 'The branch does not have a branch policy.'
        Recommend 'Protect your branches with a branch policy.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#secure-azure-repos
        $Assert.HasFieldValue($TargetObject, "BranchPolicy")
        $Assert.NotNull($TargetObject, "BranchPolicy")
}

# Synopsis: The branch should have its branch policy enabled
Rule 'Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled' `
    -Ref 'ADO-RB-001a' `
    -Type 'Azure.DevOps.Repo.Branch' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description: The default branch should have its branch policy enabled
        Reason 'The default branch does not have its branch policy enabled.'
        Recommend 'Protect your main branch with a branch policy.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#secure-azure-repos
        $policies = @($TargetObject.BranchPolicy | Where-Object { $_.isEnabled -eq $true -and $_.isBlocking -eq $true })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The branch policy should require a minimum number of reviewers
Rule 'Azure.DevOps.Repos.Branch.BranchPolicyMinimumReviewers' `
    -Ref 'ADO-RB-002' `
    -Type 'Azure.DevOps.Repo.Branch' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description: The branch policy should require a minimum number of reviewers
        Reason 'The branch policy does not require any reviewers.'
        Recommend 'Require a minimum number of reviewers to approve pull requests.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#repositories-and-branches
        $policies = @($TargetObject.BranchPolicy | Where-Object {
            $_.type.id -eq 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' -and
            $_.isEnabled -eq $true -and $_.isBlocking -eq $true -and
            $null -ne $_.settings.minimumApproverCount -and
            $_.settings.minimumApproverCount -ge $Configuration.GetValueOrDefault('branchMinimumApproverCount', 1)
        })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The branch policy should not allow creators to approve their own changes
Rule 'Azure.DevOps.Repos.Branch.BranchPolicyAllowSelfApproval' `
    -Ref 'ADO-RB-003' `
    -Type 'Azure.DevOps.Repo.Branch' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description: The branch policy should not allow creators to approve their own changes
        Reason 'The branch policy allows creators to approve their own changes.'
        Recommend 'Do not allow users to approve their own changes.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#policies
        $policies = @($TargetObject.BranchPolicy | Where-Object {
            $_.type.id -eq 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' -and
            $_.isEnabled -eq $true -and $_.isBlocking -eq $true -and
            $_.settings.creatorVoteCounts -eq $false
        })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The branch policy should reset code reviewer votes when new changes are pushed
Rule 'Azure.DevOps.Repos.Branch.BranchPolicyResetVotes' `
    -Ref 'ADO-RB-004' `
    -Type 'Azure.DevOps.Repo.Branch' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description: The branch policy should reset code reviewer votes when new changes are pushed
        Reason 'The branch policy does not reset code reviewer votes when new changes are pushed.'
        Recommend 'Reset code reviewer votes when new changes are pushed.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#policies
        $policies = @($TargetObject.BranchPolicy | Where-Object {
            $_.type.id -eq 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' -and
            $_.isEnabled -eq $true -and $_.isBlocking -eq $true -and
            $_.settings.resetOnSourcePush -eq $true
        })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The branch policy enforce linked work items
Rule 'Azure.DevOps.Repos.Branch.BranchPolicyEnforceLinkedWorkItems' `
    -Ref 'ADO-RB-007' `
    -Type 'Azure.DevOps.Repo.Branch' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description 'The branch policy enforce linked work items.'
        Reason 'The branch policy does not enforce linked work items.'
        Recommend 'Enforce linked work items.'
        # Links 'https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#enforce-linked-work-items'
        $policies = @($TargetObject.BranchPolicy | Where-Object {
            $_.type.id -eq '40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e' -and
            $_.isEnabled -eq $true -and $_.isBlocking -eq $true
        })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The branch policy should enforce comment resolution
Rule 'Azure.DevOps.Repos.Branch.BranchPolicyCommentResolution' `
    -Ref 'ADO-RB-008' `
    -Type 'Azure.DevOps.Repo.Branch' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description 'The branch policy should enforce comment resolution'
        Reason 'The branch policy does not enforce comment resolution'
        Recommend 'Enforce comment resolution'
        # Links 'https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#enforce-comment-resolution'
        $policies = @($TargetObject.BranchPolicy | Where-Object {
            $_.type.id -eq 'c6a1889d-b943-4856-b76f-9e46bb6b0df2' -and
            $_.isEnabled -eq $true -and $_.isBlocking -eq $true
        })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The branch policy should require a merge strategy
Rule 'Azure.DevOps.Repos.Branch.BranchPolicyMergeStrategy' `
    -Ref 'ADO-RB-009' `
    -Type 'Azure.DevOps.Repo.Branch' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description 'The branch policy should require a merge strategy'
        Reason 'The branch policy does not require a merge strategy'
        Recommend 'Consider requiring a merge strategy'
        # Links 'https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#require-a-merge-strategy'
        $policies = @($TargetObject.BranchPolicy | Where-Object {
            $_.type.id -eq 'fa4e907d-c16b-4a4c-9dfa-4916e5d171ab' -and
            $_.isEnabled -eq $true -and $_.isBlocking -eq $true -and
            ($_.settings.allowSquash -eq $true -or $_.settings.allowRebase -eq $true -or
             $_.settings.allowNoFastForward -eq $true -or $_.settings.allowRebaseMerge -eq $true)
        })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The branch policy should require a build/pipeline to pass
Rule 'Azure.DevOps.Repos.Branch.BranchPolicyRequireBuild' `
    -Ref 'ADO-RB-013' `
    -Type 'Azure.DevOps.Repo.Branch' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description 'The branch policy should require a build/pipeline to pass'
        Reason 'The branch policy does not require a build/pipeline to pass'
        Recommend 'Consider requiring a build/pipeline to pass'
        # Links 'https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops'
        $policies = @($TargetObject.BranchPolicy | Where-Object {
            $_.type.id -eq '0609b952-1397-4640-95ec-e00a01b2c241' -and
            $_.isEnabled -eq $true -and $_.isBlocking -eq $true -and
            $null -ne $_.settings.buildDefinitionId -and $_.settings.buildDefinitionId -gt 0
        })
        $Assert.Greater($policies, 'Count', 0)
}

# Synopsis: The branch should have a commit in the last 90 days
Rule 'Azure.DevOps.Repos.Branch.CommitRecent' `
    -Ref 'ADO-RB-014' `
    -Type 'Azure.DevOps.Repo.Branch' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description: The branch should have a commit in the last 90 days
        Reason 'The branch does not have a commit in the last 90 days.'
        Recommend 'Consider merging the branch or deleting it.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops#repositories-and-branches
        If ([datetime]$TargetObject.Stats.commit.committer.date -ge (Get-Date).AddDays(-($Configuration.GetValueOrDefault('lastCommitDays', 90)))) {
            $Assert.Pass()
        } else {
            $Assert.Fail('The branch does not have a commit in the last 90 days.')
        }
}
