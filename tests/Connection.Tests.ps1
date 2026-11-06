BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Connect-AzDevOps authentication modes' -Tag 'Unit' {
    BeforeEach {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Disconnect-AzDevOps
            Mock Invoke-RestMethod { [pscustomobject]@{ value = @() } }
        }
    }

    It 'creates a PAT connection with the supplied token profile and organization identifier' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Connect-AzDevOps -Organization test-org -OrganizationId test-org-id -PAT test-pat -TokenType ReadOnly
            $script:connection.AuthType | Should -Be 'PAT'
            $script:connection.TokenType | Should -Be 'ReadOnly'
            $script:connection.OrganizationId | Should -Be 'test-org-id'
            $script:connection.GetHeader().Authorization | Should -Match '^Basic '
            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly
        }
    }

    It 'creates a service-principal connection and obtains a token' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Mock Invoke-RestMethod { [pscustomobject]@{ access_token = 'service-principal-token'; expires_in = 3600 } } -ParameterFilter { $Method -eq 'Post' }
            Mock Invoke-RestMethod { [pscustomobject]@{ value = @() } } -ParameterFilter { $Method -eq 'Get' }
            Connect-AzDevOps -Organization test-org -OrganizationId test-org-id -TenantId tenant -ClientId client -ClientSecret secret -TokenType FineGrained
            $script:connection.AuthType | Should -Be 'ServicePrincipal'
            $script:connection.TokenType | Should -Be 'FineGrained'
            $script:connection.OrganizationId | Should -Be 'test-org-id'
            $script:connection.GetHeader().Authorization | Should -Be 'Bearer service-principal-token'
            Assert-MockCalled Invoke-RestMethod -ParameterFilter { $Method -eq 'Post' } -Times 1 -Exactly
            Assert-MockCalled Invoke-RestMethod -ParameterFilter { $Method -eq 'Get' } -Times 1 -Exactly
        }
    }

    It 'creates a managed-identity connection and obtains a token' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Mock Invoke-RestMethod { [pscustomobject]@{ access_token = 'managed-identity-token'; expires_on = ([DateTimeOffset]::UtcNow.AddHours(1).ToUnixTimeSeconds()) } } -ParameterFilter { $Method -eq 'Get' }
            Connect-AzDevOps -Organization test-org -OrganizationId test-org-id -ManagedIdentity
            $script:connection.AuthType | Should -Be 'ManagedIdentity'
            $script:connection.TokenExpires.Kind | Should -Be Utc
            $script:connection.TokenExpires | Should -BeGreaterThan ([DateTime]::UtcNow.AddMinutes(59))
            $script:connection.OrganizationId | Should -Be 'test-org-id'
            $script:connection.GetHeader().Authorization | Should -Be 'Bearer managed-identity-token'
            Assert-MockCalled Invoke-RestMethod -ParameterFilter { $Method -eq 'Get' } -Times 2 -Exactly
        }
    }

    It 'creates a bearer connection and preserves its organization identifier' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Connect-AzDevOps -Organization test-org -OrganizationId test-org-id -AccessToken 'header.payload.signature'
            $script:connection.AuthType | Should -Be 'Bearer'
            $script:connection.OrganizationId | Should -Be 'test-org-id'
            $script:connection.GetHeader().Authorization | Should -Be 'Bearer header.payload.signature'
            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly
        }
    }

    It 'discovers the organization GUID for OAuth when only the name is supplied' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Mock Invoke-RestMethod { [pscustomobject]@{ instanceId = '5e433049-1396-4a9d-80b2-33dc2f1e98af' } } -ParameterFilter { $Uri -like '*_apis/connectionData?api-version=7.1-preview' }
            Connect-AzDevOps -Organization test-org -AccessToken 'header.payload.signature'
            $script:connection.OrganizationId | Should -Be '5e433049-1396-4a9d-80b2-33dc2f1e98af'
            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Uri -like '*_apis/connectionData?api-version=7.1-preview' }
        }
    }

    It 'rejects an invalid organization GUID returned by discovery' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Mock Invoke-RestMethod { [pscustomobject]@{ instanceId = 'not-a-guid' } } -ParameterFilter { $Uri -like '*_apis/connectionData?api-version=7.1-preview' }
            { Connect-AzDevOps -Organization test-org -AccessToken 'header.payload.signature' } | Should -Throw '*did not return a valid organization GUID*'
            $script:connection | Should -BeNullOrEmpty
        }
    }

    It 'does not query connectionData when the GUID is explicitly supplied' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Connect-AzDevOps -Organization test-org -OrganizationId '5e433049-1396-4a9d-80b2-33dc2f1e98af' -AccessToken 'header.payload.signature'
            Assert-MockCalled Invoke-RestMethod -Times 0 -Exactly -ParameterFilter { $Uri -like '*_apis/connectionData*' }
        }
    }

    It 'reports service-principal authentication failures at the token boundary' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Mock Invoke-RestMethod { throw 'invalid client secret' } -ParameterFilter { $Method -eq 'Post' }
            { Connect-AzDevOps -Organization test-org -TenantId tenant -ClientId client -ClientSecret wrong } | Should -Throw '*Failed to connect to Azure DevOps*'
            Assert-MockCalled Invoke-RestMethod -ParameterFilter { $Method -eq 'Post' } -Times 1 -Exactly
        }
    }
}

AfterAll {
    Remove-Module DevOpsTools.AzureDevOps.PSRule -Force
}
