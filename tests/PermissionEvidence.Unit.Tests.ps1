BeforeAll {
    Import-Module "$PSScriptRoot/../src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psd1" -Force
}
Describe 'Permission evidence collection' -Tag 'Unit' {
        BeforeEach {
            InModuleScope PSRule.Rules.AzureDevOps {
            $script:connection = [pscustomobject]@{ Organization = 'fixture' }
            $script:connection | Add-Member -MemberType ScriptMethod -Name GetHeader -Value { @{} }
            Mock Invoke-RestMethod {
                if ($Uri -like '*securitynamespaces*') {
                    return [pscustomobject]@{ value = @([pscustomobject]@{
                        namespaceId = '33344d9c-fc72-4d6f-aba5-fa317101a7e9'
                        structureValue = 1; useTokenTranslator = $false; separatorValue = '/'; elementLength = -1
                    }) }
                }
                if ($Uri -like '*accesscontrollists*token=project&*') {
                    return [pscustomobject]@{ count = 1; value = @([pscustomobject]@{
                        token = 'project'; inheritPermissions = $true
                        acesDictionary = [pscustomobject]@{ group = [pscustomobject]@{ descriptor = 'group'; allow = 7; deny = 0 } }
                    }) }
                }
                if ($Uri -like '*accesscontrollists*') { return [pscustomobject]@{ count = 0; value = @() } }
                if ($Uri -like '*identities?descriptors=group&*') {
                    return [pscustomobject]@{ value = @([pscustomobject]@{ descriptor = 'group'; isContainer = $true; members = @('nested') }) }
                }
                if ($Uri -like '*identities?descriptors=nested&*') {
                    return [pscustomobject]@{ value = @([pscustomobject]@{ descriptor = 'nested'; isContainer = $true; members = @('user') }) }
                }
                return [pscustomobject]@{ value = @([pscustomobject]@{ descriptor = 'user'; isContainer = $false }) }
            }
            }
        }
        It 'collects ancestor grants and nested members for evaluation' {
            InModuleScope PSRule.Rules.AzureDevOps {
            $evidence = Get-AzDevOpsPermissionEvidence -NamespaceId '33344d9c-fc72-4d6f-aba5-fa317101a7e9' -Token 'project/pipeline' -AdministrativeBypass @{} -AdministrativeEvidenceReference 'synthetic-review-v1'
            $evidence.Status | Should -Be 'Complete'
            $evidence.Acls.Count | Should -Be 3
            $evidence.Identities.Count | Should -Be 3
            $policy = @{ Reference = 'policy-v1'; NamespaceId = $evidence.NamespaceId; SensitiveMask = 6; Allowed = @{} }
            (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Fail'
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -like '*token=project%2Fpipeline&includeExtendedInfo=true*' }
            }
        }
        It 'does not assume absence of administrative bypass' {
            InModuleScope PSRule.Rules.AzureDevOps {
            $evidence = Get-AzDevOpsPermissionEvidence -NamespaceId '33344d9c-fc72-4d6f-aba5-fa317101a7e9' -Token 'project/pipeline'
            $evidence.Status | Should -Be 'Partial'
            $evidence.ReasonCode | Should -Be 'AdministrativeEvidenceUnavailable'
            Should -Invoke Invoke-RestMethod -Times 0
            }
        }
        It 'preserves unavailable evidence when an identity request is denied' {
            InModuleScope PSRule.Rules.AzureDevOps {
            Mock Invoke-RestMethod { throw 'synthetic 403' } -ParameterFilter { $Uri -like '*identities*' }
            $evidence = Get-AzDevOpsPermissionEvidence -NamespaceId '33344d9c-fc72-4d6f-aba5-fa317101a7e9' -Token 'project/pipeline' -AdministrativeBypass @{} -AdministrativeEvidenceReference 'synthetic-review-v1'
            $evidence.Status | Should -Be 'Partial'
            $evidence.IdentitiesComplete | Should -Be $false
            }
        }
        It 'does not infer the hierarchy of a translated namespace' {
            InModuleScope PSRule.Rules.AzureDevOps {
            Mock Invoke-RestMethod {
                [pscustomobject]@{ value = @([pscustomobject]@{ namespaceId = '33344d9c-fc72-4d6f-aba5-fa317101a7e9'; useTokenTranslator = $true; structureValue = 1 }) }
            } -ParameterFilter { $Uri -like '*securitynamespaces*' }
            $evidence = Get-AzDevOpsPermissionEvidence -NamespaceId '33344d9c-fc72-4d6f-aba5-fa317101a7e9' -Token 'project/pipeline' -AdministrativeBypass @{} -AdministrativeEvidenceReference 'synthetic-review-v1'
            $evidence.ScopeComplete | Should -Be $false
            $evidence.Status | Should -Be 'Partial'
            }
        }
        AfterEach { InModuleScope PSRule.Rules.AzureDevOps { $script:connection = $null } }
}
AfterAll { Remove-Module PSRule.Rules.AzureDevOps -Force }
