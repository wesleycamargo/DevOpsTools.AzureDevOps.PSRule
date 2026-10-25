using module ../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1
BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

# Live authentication against Azure DevOps. Service principal tests need ADO_CLIENT_ID,
# ADO_CLIENT_SECRET, and ADO_TENANT_ID; managed identity tests only work on Azure-hosted agents.
Describe "Functions: Authentication.Tests" -Tag 'Authentication' {
    Context " Connect-AzDevOps with a Personal Access Token" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -PAT $env:ADO_PAT
            $connection = InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection }
        }

        It " The connection should not be null" {
            $connection | Should -Not -BeNullOrEmpty
        }

        # It " The connection should be of type AzureDevOpsConnection" {
        #     $connection | Should -BeOfType [AzureDevOpsConnection]
        # }

        It " The connection should have a token" {
            $connection.Token | Should -Not -BeNullOrEmpty
        }

        It " The connection should have a token that expires in the future" {
            $connection.TokenExpires | Should -BeGreaterThan (Get-Date)
        }

        It " should run Get-AzDevOpsProject" {
            $projects = Get-AzDevOpsProject
            $projects | Should -Not -BeNullOrEmpty
        }
    }

    Context " Connect-AzDevOps with a Service Principal" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -ClientId $env:ADO_CLIENT_ID -ClientSecret $env:ADO_CLIENT_SECRET -TenantId $env:ADO_TENANT_ID
            $connection = InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection }
        }

        It " The connection should not be null" {
            $connection | Should -Not -BeNullOrEmpty
        }

        # It " The connection should be of type AzureDevOpsConnection" {
        #     $connection | Should -BeOfType [AzureDevOpsConnection]
        # }

        It " The connection should have a token" {
            $connection.Token | Should -Not -BeNullOrEmpty
        }

        It " The connection should have a token that expires in the future" {
            $connection.TokenExpires | Should -BeGreaterThan (Get-Date)
        }

        It " should run Get-AzDevOpsProject" {
            $projects = Get-AzDevOpsProject
            $projects | Should -Not -BeNullOrEmpty
        }
    }

    Context " Connect-AzDevOps with a Service Principal and an expired token" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -ClientId $env:ADO_CLIENT_ID -ClientSecret $env:ADO_CLIENT_SECRET -TenantId $env:ADO_TENANT_ID
            InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection.TokenExpires = [System.DateTime]::MinValue }
            $projects = Get-AzDevOpsProject
            $connection = InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection }
        }

        It " The connection should not be null" {
            $connection | Should -Not -BeNullOrEmpty
        }

        It " The connection should have a token" {
            $connection.Token | Should -Not -BeNullOrEmpty
        }

        It " The connection should have a token that expires in the future" {
            $connection.TokenExpires | Should -BeGreaterThan (Get-Date)
        }

        It " should run Get-AzDevOpsProject" {
            $projects | Should -Not -BeNullOrEmpty
        }
    }

    Context " Connect-AzDevOps with a Service Principal and a wrong secret" {
        It " The operation should fail with a wrong secret" {
            { 
                Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -ClientId $env:ADO_CLIENT_ID -ClientSecret 'wrong' -TenantId $env:ADO_TENANT_ID
            } | Should -Throw 
        }
    }

    Context " Connect-AzDevOps with a User Assigned Managed Identity" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -ManagedIdentity
            $connection = InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection }
        }

        It " The connection should not be null" {
            $connection | Should -Not -BeNullOrEmpty
        }

        It " The connection should have a token" {
            $connection.Token | Should -Not -BeNullOrEmpty
        }

        It " The connection should have a token that expires in the future" {
            $connection.TokenExpires | Should -BeGreaterThan (Get-Date)
        }

        It " should run Get-AzDevOpsProject" {
            $projects = Get-AzDevOpsProject
            $projects | Should -Not -BeNullOrEmpty
        }
    }

    Context " Connect-AzDevOps with a User Assigned Managed Identity and an expired token" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -ManagedIdentity
            InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection.TokenExpires = [System.DateTime]::MinValue }
            $projects = Get-AzDevOpsProject
            $connection = InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection }
        }

        It " The connection should not be null" {
            $connection | Should -Not -BeNullOrEmpty
        }

        It " The connection should have a token" {
            $connection.Token | Should -Not -BeNullOrEmpty
        }

        It " The connection should have a token that expires in the future" {
            $connection.TokenExpires | Should -BeGreaterThan (Get-Date)
        }

        It " should run Get-AzDevOpsProject" {
            $projects | Should -Not -BeNullOrEmpty
        }
    }

    Context " Connect-AzDevOps with a System Assigned Managed Identity" {
        BeforeAll {
            Remove-Item Env:\ADO_MSI_CLIENT_ID
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -ManagedIdentity
            $connection = InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection }
        }

        It " The connection should not be null" {
            $connection | Should -Not -BeNullOrEmpty
        }

        It " The connection should have a token" {
            $connection.Token | Should -Not -BeNullOrEmpty
        }

        It " The connection should have a token that expires in the future" {
            $connection.TokenExpires | Should -BeGreaterThan (Get-Date)
        }
    }
    
    Context " Disconnect-AzDevOps" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -PAT $env:ADO_PAT
            Disconnect-AzDevOps
            $connection = InModuleScope DevOpsTools.AzureDevOps.PSRule { $script:connection }
        }

        It " The connection should be null" {
            $connection | Should -BeNullOrEmpty
        }
    }
}
