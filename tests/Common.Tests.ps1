using module ../src/DevOpsTools.AzureDevOps.Assessment/DevOpsTools.AzureDevOps.Assessment.psd1
BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.Assessment/DevOpsTools.AzureDevOps.Assessment.psd1" -Force
}

Describe "Functions: Common.Tests" -Tag 'Integration' {
    Context " Get-AzDevOpsProject without a connection" -Tag 'Unit' {
        It " should throw an error" {
            { 
                Disconnect-AzDevOps
                Get-AzDevOpsProject
            } | Should -Throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
        }
    }

    Context " Get-AzDevOpsProject" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -PAT $env:ADO_PAT
            $projects = Get-AzDevOpsProject
        }

        It " The projects should not be null" {
            $projects | Should -Not -BeNullOrEmpty
        }

        It " The projects should be of type [PSCustomObject]" {
            $projects | Should -BeOfType [PSCustomObject]
        }

        It " The projects should have at least one project" {
            $projects.Count | Should -BeGreaterThan 0
        }

        It " The projects should have a project named $env:ADO_PROJECT" {
            $projects | Select -ExpandProperty name | Should -Contain $env:ADO_PROJECT
        }

        It " The projects should have a project named $env:ADO_PROJECT with an id" {
            $projects | Where-Object { $_.name -eq $env:ADO_PROJECT } | Select -ExpandProperty id | Should -Not -BeNullOrEmpty
        }

        It " The -Project Parameter should return a single result for $env:ADO_PROJECT" {
            $project = Get-AzDevOpsProject -Project $env:ADO_PROJECT
            $project | Should -Not -BeNullOrEmpty
        }

        It " The -Project Parameter should throw on a non-existing project" {
            { 
                Get-AzDevOpsProject -Project 'wrong'
            } | Should -Throw
        }

        It " The operation should fail with a wrong Organization" {
            { 
                Connect-AzDevOps -Organization 'wrong' -PAT $env:ADO_PAT
                Get-AzDevOpsProject -ErrorAction Stop
            } | Should -Throw 
        }

        It " The operation should fail with a wrong PAT" {
            { 
                Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -PAT 'wrong'
                Get-AzDevOpsProject -ErrorAction Stop
            } | Should -Throw 
        }
    }

    Context " Get-AzDevOpsProjectAcls without a connection" -Tag 'Unit' {
        It " should throw an error" {
            { 
                Disconnect-AzDevOps
                InModuleScope DevOpsTools.AzureDevOps.Assessment -Parameters @{ ProjectId = '00000000-0000-0000-0000-000000000001' } {
                    param($ProjectId)
                    Get-AzDevOpsProjectAcls -ProjectId $ProjectId
                }
            } | Should -Throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
        }
    }

    Context " Get-AzDevOpsProjectAcls" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -PAT $env:ADO_PAT
            $project = Get-AzDevOpsProject -Project $env:ADO_PROJECT
            $acls = InModuleScope DevOpsTools.AzureDevOps.Assessment -Parameters @{ ProjectId = $project.id } {
                param($ProjectId)
                Get-AzDevOpsProjectAcls -ProjectId $ProjectId
            }
        }

        It " The acls should not be null" {
            $acls | Should -Not -BeNullOrEmpty
        }

        It " The acls should be of type [Hashtable]" {
            $acls | Should -BeOfType [Hashtable]
        }

        It " The operation should fail with a wrong Organization" {
            { 
                Connect-AzDevOps -Organization 'wrong' -PAT $env:ADO_PAT
                InModuleScope DevOpsTools.AzureDevOps.Assessment -Parameters @{ ProjectId = $project.id } {
                    param($ProjectId)
                    Get-AzDevOpsProjectAcls -ProjectId $ProjectId -ErrorAction Stop
                }
            } | Should -Throw 
        }

        It " The operation should fail with a wrong PAT" {
            { 
                Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -PAT 'wrong'
                InModuleScope DevOpsTools.AzureDevOps.Assessment -Parameters @{ ProjectId = $project.id } {
                    param($ProjectId)
                    Get-AzDevOpsProjectAcls -ProjectId $ProjectId -ErrorAction Stop
                }
            } | Should -Throw 
        }
    }

    Context " Export-AzDevOpsProject without a connection" -Tag 'Unit' {
        It " should throw an error" {
            { 
                Disconnect-AzDevOps
                Export-AzDevOpsProject -Project 'test-project' -OutputPath $TestDrive
            } | Should -Throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
        }
    }

    Context " Export-AzDevOpsProject" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -PAT $env:ADO_PAT
            $project = Get-AzDevOpsProject -Project $env:ADO_PROJECT
            Export-AzDevOpsProject -Project $project.name -OutputPath $env:ADO_EXPORT_DIR
        }

        It " The output folder should contain a file named $env:ADO_PROJECT.prj.ado.json" {
            $file = Join-Path -Path $env:ADO_EXPORT_DIR -ChildPath "$env:ADO_PROJECT.prj.ado.json"
            Test-Path -Path $file | Should -Be $true
        }

        It " The output folder should contain a file named $env:ADO_PROJECT.prj.ado.json with a size greater than 0" {
            $file = Join-Path -Path $env:ADO_EXPORT_DIR -ChildPath "$env:ADO_PROJECT.prj.ado.json"
            (Get-Item $file).length | Should -BeGreaterThan 0
        }

        It " Should throw on a non-existing project" {
            { 
                Export-AzDevOpsProject -Project 'wrong' -OutputPath $env:ADO_EXPORT_DIR
            } | Should -Throw
        }

        It " The operation should fail with a wrong Organization" {
            { 
                Disconnect-AzDevOps
                Connect-AzDevOps -Organization 'wrong' -PAT $env:ADO_PAT
                Export-AzDevOpsProject -Project $env:ADO_PROJECT -OutputPath $env:ADO_EXPORT_DIR -ErrorAction Stop
            } | Should -Throw 
        }

        It " The operation should fail with a wrong PAT" {
            { 
                Disconnect-AzDevOps
                Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -PAT 'wrong'
                Export-AzDevOpsProject -Project $env:ADO_PROJECT -OutputPath $env:ADO_EXPORT_DIR -ErrorAction Stop
            } | Should -Throw 
        }
    }

    Context " Export-AzDevOpsProject -PassThru" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -PAT $env:ADO_PAT
            $project = Get-AzDevOpsProject -Project $env:ADO_PROJECT
            $projectDetails = Export-AzDevOpsProject -Project $project.name -PassThru
            $ruleResult = $projectDetails | Invoke-PSRule -Module @('DevOpsTools.AzureDevOps.Assessment') -Culture en
        }

        It " The output should be of type [PSCustomObject]" {
            $projectDetails | Should -BeOfType [PSCustomObject]
        }

        It " The output should have a ObjectType property" {
            $projectDetails | Select -ExpandProperty ObjectType | Should -Not -BeNullOrEmpty
        }

        It " The output should have a ObjectName property" {
            $projectDetails | Select -ExpandProperty ObjectName | Should -Not -BeNullOrEmpty
        }

        It " The output should have results with Invoke-PSRule" {
            $ruleResult | Should -Not -BeNullOrEmpty
        }

        It " The output should have results with Invoke-PSRule that are of type [PSRule.Rules.RuleRecord]" {
            $ruleResult[0] | Should -BeOfType [PSRule.Rules.RuleRecord]
        }

        AfterAll {
            Disconnect-AzDevOps
        }
    }
}

AfterAll {
}
