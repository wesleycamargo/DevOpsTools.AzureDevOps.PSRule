BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}
Describe 'Permission evidence collection' -Tag 'Unit' {
    BeforeEach {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $script:connection = [pscustomobject]@{ Organization = 'fixture' }
            $script:connection | Add-Member -MemberType ScriptMethod -Name GetHeader -Value { @{} }
            Mock Invoke-RestMethod {
                if ($Uri -like '*securitynamespaces*') {
                    return [pscustomobject]@{ value = @([pscustomobject]@{ namespaceId = '33344d9c-fc72-4d6f-aba5-fa317101a7e9'; useTokenTranslator = $false }) }
                }
                if ($Uri -like '*accesscontrollists*token=project%2Fpipeline*') {
                    return [pscustomobject]@{ count = 1; value = @([pscustomobject]@{ token = 'project/pipeline'; inheritPermissions = $true; acesDictionary = [pscustomobject]@{} }) }
                }
                throw 'Unexpected request'
            }
        }
    }
    It 'defines all ACL security namespaces once with descriptive names' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $script:AzureDevOpsEnvironmentSecurityNamespaceId | Should -Be ([guid]'83d4c2e6-e57d-4d6e-892b-b87222b7ad20')
            $script:AzureDevOpsReleaseManagementSecurityNamespaceId | Should -Be ([guid]'c788c23e-1b46-4162-8f5e-d7585343b5de')
            $script:AzureDevOpsGitRepositoriesSecurityNamespaceId | Should -Be ([guid]'2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87')
            $script:AzureDevOpsServiceEndpointsSecurityNamespaceId | Should -Be ([guid]'49b48001-ca20-4adc-8111-5b60c903a50c')
            $script:AzureDevOpsLibrarySecurityNamespaceId | Should -Be ([guid]'b7e84409-6553-448a-bbb2-af228e07cbeb')
        }
    }
    It 'defines the Azure DevOps Build security namespace once for pipeline ACL collection' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $script:AzureDevOpsBuildSecurityNamespaceId | Should -Be ([guid]'33344d9c-fc72-4d6f-aba5-fa317101a7e9')
        }
    }
    It 'records a successful empty direct ACL scope as complete' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $evidence = Get-AzDevOpsPermissionEvidence -NamespaceId '33344d9c-fc72-4d6f-aba5-fa317101a7e9' -Token 'project/pipeline'
            $evidence.Status | Should -Be 'Complete'
            $evidence.ScopeComplete | Should -BeTrue
            $evidence.Acls.Count | Should -Be 1
            $evidence.Acls[0].token | Should -Be 'project/pipeline'
        }
    }
    It 'does not accept a nonempty response for another ACL scope as complete' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Mock Invoke-RestMethod {
                [pscustomobject]@{ count = 1; value = @([pscustomobject]@{ token = 'project/other'; inheritPermissions = $true; acesDictionary = [pscustomobject]@{} }) }
            } -ParameterFilter { $Uri -like '*accesscontrollists*' }
            $evidence = Get-AzDevOpsPermissionEvidence -NamespaceId '33344d9c-fc72-4d6f-aba5-fa317101a7e9' -Token 'project/pipeline'
            $evidence.Status | Should -Be 'Partial'
            $evidence.ScopeComplete | Should -BeFalse
        }
    }
    It 'preserves failed ACL collection as incomplete evidence' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Mock Invoke-RestMethod { throw 'synthetic 403' } -ParameterFilter { $Uri -like '*accesscontrollists*' }
            $evidence = Get-AzDevOpsPermissionEvidence -NamespaceId '33344d9c-fc72-4d6f-aba5-fa317101a7e9' -Token 'project/pipeline'
            $evidence.Status | Should -Be 'Partial'
            $evidence.ReasonCode | Should -Be 'PermissionCollectionUnavailable'
        }
    }
    AfterEach { InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection = $null } }
}
AfterAll { Remove-Module DevOpsTools.AzureDevOps.PSRule -Force }
