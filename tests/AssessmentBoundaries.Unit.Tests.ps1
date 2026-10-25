BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.Assessment/DevOpsTools.AzureDevOps.Assessment.psd1" -Force
}

Describe 'Assessment evidence boundaries' -Tag Unit {
    Context 'Mandatory branch policies' {
        It 'requires an enabled blocking <Kind> policy (<Enabled>, <Blocking>)' -ForEach @(
            @{ Kind = 'MinimumReviewers'; TypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'; Enabled = $false; Blocking = $true; Outcome = 'Fail' }
            @{ Kind = 'MinimumReviewers'; TypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'; Enabled = $true; Blocking = $false; Outcome = 'Fail' }
            @{ Kind = 'MinimumReviewers'; TypeId = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'; Enabled = $true; Blocking = $true; Outcome = 'Pass' }
            @{ Kind = 'RequireBuild'; TypeId = '0609b952-1397-4640-95ec-e00a01b2c241'; Enabled = $true; Blocking = $false; Outcome = 'Fail' }
            @{ Kind = 'RequireBuild'; TypeId = '0609b952-1397-4640-95ec-e00a01b2c241'; Enabled = $false; Blocking = $true; Outcome = 'Fail' }
            @{ Kind = 'RequireBuild'; TypeId = '0609b952-1397-4640-95ec-e00a01b2c241'; Enabled = $true; Blocking = $true; Outcome = 'Pass' }
        ) {
            $target = [pscustomobject]@{
                ObjectType = 'Azure.DevOps.Repo'; ObjectName = 'fixture.repo'
                MainBranchPolicy = @([pscustomobject]@{
                    isEnabled = $Enabled; isBlocking = $Blocking
                    type = @{ id = $TypeId; displayName = 'Build' }
                    settings = @{ minimumApproverCount = 2; buildDefinitionId = 1 }
                })
            }
            $result = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name "Azure.DevOps.Repos.DefaultBranchPolicy$Kind" -Culture en)
            $result[0].Outcome | Should -Be $Outcome
        }

        It 'checks enforcement for <Kind> (<Blocking>)' -ForEach @(
            @{ Kind = 'EnforceLinkedWorkItems'; TypeId = '40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e'; Blocking = $false; Outcome = 'Fail' }
            @{ Kind = 'EnforceLinkedWorkItems'; TypeId = '40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e'; Blocking = $true; Outcome = 'Pass' }
            @{ Kind = 'CommentResolution'; TypeId = 'c6a1889d-b943-4856-b76f-9e46bb6b0df2'; Blocking = $false; Outcome = 'Fail' }
            @{ Kind = 'CommentResolution'; TypeId = 'c6a1889d-b943-4856-b76f-9e46bb6b0df2'; Blocking = $true; Outcome = 'Pass' }
            @{ Kind = 'MergeStrategy'; TypeId = 'fa4e907d-c16b-4a4c-9dfa-4916e5d171ab'; Blocking = $false; Outcome = 'Fail' }
            @{ Kind = 'MergeStrategy'; TypeId = 'fa4e907d-c16b-4a4c-9dfa-4916e5d171ab'; Blocking = $true; Outcome = 'Pass' }
        ) {
            $target = [pscustomobject]@{
                ObjectType = 'Azure.DevOps.Repo'; ObjectName = 'fixture.repo'
                MainBranchPolicy = @([pscustomobject]@{ isEnabled = $true; isBlocking = $Blocking; type = @{ id = $TypeId }; settings = @{ allowSquash = $true } })
            }
            $result = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name "Azure.DevOps.Repos.DefaultBranchPolicy$Kind" -Culture en)
            $result[0].Outcome | Should -Be $Outcome
        }

        It 'accepts an enforced reviewer policy among multiple applicable policies' {
            $target = [pscustomobject]@{
                ObjectType = 'Azure.DevOps.Repo'; ObjectName = 'fixture.multiple'
                MainBranchPolicy = @(
                    @{ isEnabled = $true; isBlocking = $true; type = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }; settings = @{ minimumApproverCount = 2 } }
                    @{ isEnabled = $false; isBlocking = $true; type = @{ id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }; settings = @{ minimumApproverCount = 0 } }
                )
            }
            $result = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers -Culture en)
            $result[0].Outcome | Should -Be Pass
        }
    }

    Context 'Collection requests' {
        BeforeEach {
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-RestMethod { [pscustomobject]@{ value = @() } }
            Connect-AzDevOps -Organization fixture-org -PAT fixture-token
        }

        It 'matches <Name> branch scopes atomically' -ForEach @(
            @{ Name = 'exact'; Scopes = @(@{ repositoryId = 'repo'; refName = 'refs/heads/main'; matchKind = 'Exact' }); Count = 1 }
            @{ Name = 'prefix'; Scopes = @(@{ repositoryId = 'repo'; refName = 'refs/heads/'; matchKind = 'Prefix' }); Count = 1 }
            @{ Name = 'all repositories'; Scopes = @(@{ repositoryId = $null; refName = 'refs/heads/main'; matchKind = 'Exact' }); Count = 1 }
            @{ Name = 'crossed'; Scopes = @(@{ repositoryId = 'other'; refName = 'refs/heads/main'; matchKind = 'Exact' }, @{ repositoryId = 'repo'; refName = 'refs/heads/other'; matchKind = 'Exact' }); Count = 0 }
            @{ Name = 'case sensitive'; Scopes = @(@{ repositoryId = 'repo'; refName = 'refs/heads/Main'; matchKind = 'Exact' }); Count = 0 }
        ) {
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-RestMethod { [pscustomobject]@{ value = @([pscustomobject]@{ settings = @{ scope = $Scopes } }) } }
            @(Get-AzDevOpsBranchPolicy -Project project -Repository repo -Branch refs/heads/main).Count | Should -Be $Count
        }

        It 'follows project continuation headers' {
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-AzDevOpsRestPage {
                [pscustomobject]@{ Body = [pscustomobject]@{ value = @([pscustomobject]@{ name = 'first' }) }; Headers = @{ 'x-ms-continuationtoken' = 'next page' } }
            } -ParameterFilter { $Uri -notmatch 'continuationToken=' }
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-AzDevOpsRestPage {
                [pscustomobject]@{ Body = [pscustomobject]@{ value = @([pscustomobject]@{ name = 'second' }) }; Headers = @{} }
            } -ParameterFilter { $Uri -match 'continuationToken=next%20page' }
            $projects = @(Get-AzDevOpsProject)
            $projects.name | Should -Be @('first', 'second')
        }

        It 'propagates a later project-page failure' {
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-AzDevOpsRestPage {
                [pscustomobject]@{ Body = [pscustomobject]@{ value = @([pscustomobject]@{ name = 'first' }) }; Headers = @{ 'x-ms-continuationtoken' = 'next' } }
            } -ParameterFilter { $Uri -notmatch 'continuationToken=' }
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-AzDevOpsRestPage { throw 'page unavailable' } -ParameterFilter { $Uri -match 'continuationToken=' }
            { Get-AzDevOpsProject } | Should -Throw
        }

        It 'does not turn a denied file request into evidence of absence' {
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-RestMethod { throw 'denied' }
            { Test-AzDevOpsFileExists -Project project -Repository repo -Path README.md } | Should -Throw
        }

        It 'distinguishes confirmed file absence from HTTP <Status> (<TypeName>)' -ForEach @(
            @{ Status = 404; TypeName = 'GitItemNotFoundException'; Missing = $true }
            @{ Status = 404; TypeName = 'GitRepositoryEmptyException'; Missing = $true }
            @{ Status = 404; TypeName = 'GitRepositoryNotFoundException'; Missing = $false }
            @{ Status = 403; TypeName = 'AccessDeniedException'; Missing = $false }
            @{ Status = 429; TypeName = 'ThrottledException'; Missing = $false }
            @{ Status = 503; TypeName = 'ServiceUnavailableException'; Missing = $false }
        ) {
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-RestMethod {
                $response = [Net.Http.HttpResponseMessage]::new([Net.HttpStatusCode]$Status)
                $exception = [Microsoft.PowerShell.Commands.HttpResponseException]::new('Synthetic request failure.', $response)
                $record = [Management.Automation.ErrorRecord]::new($exception, 'SyntheticHttpFailure', 'InvalidOperation', $null)
                $record.ErrorDetails = [Management.Automation.ErrorDetails]::new(('{"typeKey":"' + $TypeName + '"}'))
                throw $record
            }
            if ($Missing) {
                Test-AzDevOpsFileExists -Project project -Repository repo -Path README.md | Should -BeFalse
            } else {
                { Test-AzDevOpsFileExists -Project project -Repository repo -Path README.md } | Should -Throw
            }
        }

        It 'returns true for an existing file' {
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-RestMethod { [pscustomobject]@{ path = '/README.md' } }
            Test-AzDevOpsFileExists -Project project -Repository repo -Path README.md | Should -BeTrue
        }

        It 'collects every pipeline page before retrieving details' {
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-AzDevOpsRestPage {
                [pscustomobject]@{ Body = [pscustomobject]@{ value = @([pscustomobject]@{ id = 1 }) }; Headers = @{ 'x-ms-continuationtoken' = 'next' } }
            } -ParameterFilter { $Uri -notmatch 'continuationToken=' }
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-AzDevOpsRestPage {
                [pscustomobject]@{ Body = [pscustomobject]@{ value = @([pscustomobject]@{ id = 2 }) }; Headers = @{} }
            } -ParameterFilter { $Uri -match 'continuationToken=' }
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-RestMethod { [pscustomobject]@{ id = [int]($Uri -replace '.*pipelines/(\d+).*', '$1') } }
            @(Get-AzDevOpsPipelines -Project project).id | Should -Be @(1, 2)
        }

        It 'rejects repeated pagination tokens instead of looping or claiming completeness' {
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-AzDevOpsRestPage {
                [pscustomobject]@{ Body = [pscustomobject]@{ value = @() }; Headers = @{ 'x-ms-continuationtoken' = 'same' } }
            }
            { Get-AzDevOpsProject } | Should -Throw
        }

        It 'preserves the working connection after failed verification' {
            Mock -ModuleName DevOpsTools.AzureDevOps.Assessment Invoke-RestMethod { throw 'denied' }
            { Connect-AzDevOps -Organization wrong-org -PAT wrong-token } | Should -Throw
            InModuleScope DevOpsTools.AzureDevOps.Assessment { $script:connection.Organization | Should -Be 'fixture-org' }
        }
    }

    It 'does not apply production environment rules to development' {
        $target = [pscustomobject]@{ ObjectType = 'Azure.DevOps.Pipelines.Environment'; ObjectName = 'fixture.dev'; name = 'development'; checks = @() }
        $results = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name 'Azure.DevOps.Pipelines.Environments.Production*' -Culture en)
        $results.Count | Should -Be 0
    }

    It 'evaluates production service-connection controls for <Scenario>' -ForEach @(
        @{ Scenario = 'development'; Name = 'development'; Protected = $false; Count = 0; Outcome = 'None' }
        @{ Scenario = 'unprotected production'; Name = 'production'; Protected = $false; Count = 3; Outcome = 'Fail' }
        @{ Scenario = 'protected production'; Name = 'production'; Protected = $true; Count = 3; Outcome = 'Pass' }
    ) {
        $checks = if ($Protected) {
            @(@{ type = @{ name = 'Approval' }; settings = @{ approvers = @(@{ id = 'fixture-reviewer' }) } }, @{ type = @{ name = 'Branch control' }; settings = @{ displayName = 'Branch control'; inputs = @{ allowedBranches = 'refs/heads/main' } } })
        } else { @() }
        $target = [pscustomobject]@{ ObjectType = 'Azure.DevOps.ServiceConnection'; ObjectName = "fixture.$Name"; name = $Name; Checks = @($checks) }
        $option = New-PSRuleOption -Configuration @{ assessmentPolicies = @{
            'Azure.DevOps.ServiceConnections.ProductionHumanApproval' = @{ Reference = 'production-review-v1' }
        } }
        $result = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name 'Azure.DevOps.ServiceConnections.Production*' -Option $option -Culture en)
        $result.Count | Should -Be $Count
        if ($Count) { @($result | Where-Object Outcome -NE $Outcome).Count | Should -Be 0 }
    }

    It 'does not classify a checksum as a plaintext variable-group secret' {
        $target = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.Tasks.VariableGroup'; ObjectName = 'fixture.checksum'
            variables = [pscustomobject]@{ checksum = [pscustomobject]@{ value = '0123456789abcdef0123456789abcdef' } }
        }
        $results = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name 'Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets' -Culture en)
        $results.Count | Should -Be 1
        $results[0].Outcome | Should -Be 'Pass'
    }

    It 'detects the signed Azure DevOps PAT format' {
        $target = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.Tasks.VariableGroup'; ObjectName = 'fixture.pat'
            variables = [pscustomobject]@{ setting = [pscustomobject]@{ value = (('x' * 75) + 'AZDO' + ('x' * 5)) } }
        }
        $result = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets -Culture en)
        $result[0].Outcome | Should -Be Fail
        ($result[0].Reason -join ' ') | Should -Not -Match 'xxx'
    }

    It 'detects structured credentials without disclosing their values in <Rule>' -ForEach @(
        @{ Rule = 'Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets'; Type = 'Azure.DevOps.Tasks.VariableGroup' }
        @{ Rule = 'Azure.DevOps.Pipelines.Core.NoPlainTextSecrets'; Type = 'Azure.DevOps.Pipeline' }
        @{ Rule = 'Azure.DevOps.Pipelines.Releases.Definition.NoPlainTextSecrets'; Type = 'Azure.DevOps.Pipelines.Releases.Definition' }
    ) {
        $target = [pscustomobject]@{
            ObjectType = $Type; ObjectName = 'fixture.secret'; configuration = @{ type = 'designerJson' }
            variables = [pscustomobject]@{ setting = [pscustomobject]@{ value = 'password=syntheticOnly;' } }
            environments = @()
        }
        $result = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name $Rule -Culture en)
        $result.Count | Should -Be 1
        $result[0].Outcome | Should -Be Fail
        ($result[0].Reason -join ' ') | Should -Not -Match 'syntheticOnly'
    }
}
