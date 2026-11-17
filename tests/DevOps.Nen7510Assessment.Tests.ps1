BeforeAll {
    Import-Module PSRule
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'NEN 7510 pilot report' -Tag 'Unit' {
    BeforeEach {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $script:connection = [pscustomobject]@{ Organization = 'fixture' }
        }
        $project = New-Item "$TestDrive/export/pilot-team" -ItemType Directory -Force
        $otherProject = New-Item "$TestDrive/export/another-team" -ItemType Directory -Force
        $output = New-Item "$TestDrive/reports" -ItemType Directory -Force
        $policy = Join-Path $TestDrive 'policy.json'
        '{"Project":"pilot-team","ControlReference":"fixture-control","AllowedBypass":{}}' | Set-Content $policy
        $target = [ordered]@{
            ObjectType = 'Azure.DevOps.Repo'
            ObjectName = 'fixture.pilot-team.repository'
            name = 'repository'
            defaultBranch = 'refs/heads/Main'
            unsafeRawProperty = 'raw-data-must-not-be-published'
            MainBranchPolicy = @(@{
                isEnabled = $true
                isBlocking = $true
                type = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }
                settings = @{ minimumApproverCount = 1; creatorVoteCounts = $false }
            })
        }
        $target | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $otherProject.FullName 'repository.json')
        $rules = 'Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers', 'Azure.DevOps.Repos.DefaultBranchPolicyAllowSelfApproval'
    }

    It 'publishes <Expected> and keeps the existing run report unchanged' -ForEach @(
        @{ SourceCanApprove = $false; BypassOutcome = 'Pass'; Expected = 'Compliant' }
        @{ SourceCanApprove = $true; BypassOutcome = 'Pass'; Expected = 'Non-compliant' }
        @{ SourceCanApprove = $false; BypassOutcome = 'Fail'; Expected = 'Non-compliant' }
        @{ SourceCanApprove = $false; BypassOutcome = 'Unknown'; Expected = 'Not assessed' }
        @{ SourceCanApprove = $true; BypassOutcome = 'Unknown'; Expected = 'Non-compliant' }
    ) {
        $target.MainBranchPolicy[0].settings.creatorVoteCounts = $SourceCanApprove
        $target | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $project.FullName 'repository.json')
        Mock Get-AzDevOpsGitBranchBypassAssessment -ModuleName DevOpsTools.AzureDevOps.PSRule {
            [pscustomobject]@{ Outcome = $BypassOutcome; Reason = 'fixture bypass evidence'; Grants = @() }
        }
        $exportPath = Join-Path $TestDrive 'export'
        $details = @(Invoke-PSRule -InputPath "$exportPath/" -Module DevOpsTools.AzureDevOps.PSRule -Name $rules -Outcome All -Culture en -ErrorAction Stop)
        $existingPath = Join-Path $output.FullName 'assessment-results.json'
        $assessment = Export-AzDevOpsAssessmentRun -Result $details -ExportPath $exportPath -OutputPath $existingPath -Organization fixture -SourceRevision synthetic
        $before = Get-Content -LiteralPath $existingPath -Raw
        $summaryPath = Export-AzDevOpsNen7510Pilot -Assessment $assessment -ExportPath $exportPath -PolicyPath $policy -OutputDirectory $output.FullName

        $reportText = Get-Content -LiteralPath (Join-Path $output.FullName 'nen7510-results.json') -Raw
        $report = $reportText | ConvertFrom-Json
        $report.Status | Should -Be $Expected
        $report.TeamProject | Should -Be 'pilot-team'
        $report.ControlReference | Should -Be 'fixture-control'
        $report.SourceRevision | Should -Be 'synthetic'
        $report.Branches.Count | Should -Be 1
        $report.Branches[0].Branch | Should -BeExactly 'refs/heads/Main'
        $report.Branches[0].RuleEvidence.RuleId | Should -Be $rules
        $report.Branches[0].RuleEvidence[0].Outcome | Should -Be 'Pass'
        $reportText | Should -Not -Match 'raw-data-must-not-be-published|another-team'
        (Get-Content -LiteralPath $summaryPath -Raw) | Should -Match ([regex]::Escape("**$Expected**"))
        (Get-Content -LiteralPath $existingPath -Raw) | Should -BeExactly $before
        Should -Invoke Get-AzDevOpsGitBranchBypassAssessment -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 1 -Exactly
    }

    It 'keeps an unavailable project out of the pass count' {
        $assessment = [pscustomobject]@{ Organization = 'fixture'; SourceRevision = 'synthetic'; Projects = @() }
        $null = Export-AzDevOpsNen7510Pilot -Assessment $assessment -ExportPath "$TestDrive/export" -PolicyPath $policy -OutputDirectory $output.FullName
        $report = Get-Content (Join-Path $output.FullName 'nen7510-results.json') -Raw | ConvertFrom-Json
        $report.Status | Should -Be 'Not assessed'
        $report.CoverageReason | Should -Match 'Team Project unavailable'
        $report.Branches.Count | Should -Be 0
    }

    AfterEach { InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection = $null } }
}

Describe 'NEN 7510 Git default-branch permissions' -Tag 'Unit' {
    BeforeEach {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $script:connection = [pscustomobject]@{ Organization = 'fixture' }
            $script:connection | Add-Member -MemberType ScriptMethod -Name GetHeader -Value { @{} }
            $script:gitTarget = [pscustomobject]@{
                project = @{ id = '22222222-2222-2222-2222-222222222222' }
                id = '{"originalId":"33333333-3333-3333-3333-333333333333"}'
                defaultBranch = 'refs/heads/release/Main'
            }
            $script:gitTokens = @(Get-AzDevOpsGitBranchSecurityTokens -ProjectId $script:gitTarget.project.id -RepositoryId '33333333-3333-3333-3333-333333333333' -Branch $script:gitTarget.defaultBranch)
            $script:gitAcls = @{}
            $script:gitContext = @{ Acls = @{}; Identities = @{} }
            Mock Invoke-RestMethod {
                if ($Uri -like '*securitynamespaces*') {
                    return [pscustomobject]@{ value = @([pscustomobject]@{
                        namespaceId = $script:AzureDevOpsGitRepositoriesSecurityNamespaceId.ToString()
                        actions = @(
                            [pscustomobject]@{ name = 'PolicyExempt'; bit = 128 }
                            [pscustomobject]@{ name = 'PullRequestBypassPolicy'; bit = 32768 }
                        )
                    }) }
                }
                if ($Uri -like '*accesscontrollists*') {
                    $token = [Uri]::UnescapeDataString(($Uri -split 'token=|&')[1])
                    $acl = $script:gitAcls[$token]
                    if ($null -eq $acl) { return [pscustomobject]@{ count = 0; value = @() } }
                    return [pscustomobject]@{ count = 1; value = @($acl) }
                }
                if ($Uri -like '*identities*') {
                    $descriptor = [Uri]::UnescapeDataString(($Uri -split 'descriptors=|&')[1])
                    $identity = switch ($descriptor) {
                        'fixture;outer' { @{ descriptor = $descriptor; isContainer = $true; members = @('fixture;inner') } }
                        'fixture;inner' { @{ descriptor = $descriptor; isContainer = $true; members = @('fixture;user', 'fixture;outer') } }
                        'fixture;user' { @{ descriptor = @{ identityType = 'fixture'; identifier = 'user' }; isContainer = $false } }
                        default { throw 'synthetic 403' }
                    }
                    return [pscustomobject]@{ count = 1; value = @([pscustomobject]$identity) }
                }
                throw 'Unexpected request'
            }
        }
    }

    It 'encodes mixed-case nested refs with their Git ACL ancestors' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $script:gitTokens.Count | Should -Be 7
            $script:gitTokens[0] | Should -BeExactly 'repoV2/'
            $script:gitTokens[-2] | Should -BeLike '*/refs/heads/720065006c006500610073006500/'
            $script:gitTokens[-1] | Should -BeLike '*/refs/heads/720065006c006500610073006500/4d00610069006e00/'
        }
    }

    It 'resolves inherited nested group grants and distinguishes push from PR bypass' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $repoToken = $script:gitTokens[2]
            $script:gitAcls[$repoToken] = [pscustomobject]@{
                token = $repoToken
                inheritPermissions = $true
                acesDictionary = [pscustomobject]@{
                    'fixture;outer' = [pscustomobject]@{ descriptor = 'fixture;outer'; allow = 32896; deny = 0 }
                }
            }
            $approved = [pscustomobject]@{ 'fixture;inner' = @('PolicyExempt') }
            $result = Get-AzDevOpsGitBranchBypassAssessment -Repository $script:gitTarget -Context $script:gitContext -AllowedBypass $approved
            $result.Outcome | Should -Be 'Fail'
            $result.Grants.Count | Should -Be 2
            ($result.Grants | Where-Object Authorized -EQ $false).Permission | Should -Be 'PullRequestBypassPolicy'
            $result.Grants.Descriptor | Select-Object -Unique | Should -Be 'fixture;user'

            $branchToken = $script:gitTokens[-1]
            $script:gitAcls[$branchToken] = [pscustomobject]@{
                token = $branchToken
                inheritPermissions = $true
                acesDictionary = [pscustomobject]@{
                    'fixture;user' = [pscustomobject]@{ descriptor = 'fixture;user'; allow = 0; deny = 32768 }
                }
            }
            $script:gitContext.Acls.Clear()
            $result = Get-AzDevOpsGitBranchBypassAssessment -Repository $script:gitTarget -Context $script:gitContext -AllowedBypass $approved
            $result.Outcome | Should -Be 'Pass'
            $result.Grants.Permission | Should -Be 'PolicyExempt'

            $script:gitAcls[$branchToken].inheritPermissions = $false
            $script:gitContext.Acls.Clear()
            $result = Get-AzDevOpsGitBranchBypassAssessment -Repository $script:gitTarget -Context $script:gitContext -AllowedBypass $approved
            $result.Outcome | Should -Be 'Pass'
            $result.Grants.Count | Should -Be 0
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Uri -like '*securitynamespaces*' }
        }
    }

    It 'reports incomplete ACL data without exposing API errors' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Mock Invoke-RestMethod { throw 'private API error' } -ParameterFilter { $Uri -like '*accesscontrollists*' }
            $result = Get-AzDevOpsGitBranchBypassAssessment -Repository $script:gitTarget -Context $script:gitContext -AllowedBypass ([pscustomobject]@{})
            $result.Outcome | Should -Be 'Unknown'
            $result.Grants.Count | Should -Be 0
            ($result | ConvertTo-Json) | Should -Not -Match 'private API error'
        }
    }

    AfterEach { InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection = $null } }
}
AfterAll { Remove-Module DevOpsTools.AzureDevOps.PSRule -Force }
