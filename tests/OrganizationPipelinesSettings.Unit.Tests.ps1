BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Read-AdoOrganizationPipelinesSettings with an explicit token' -Tag 'Unit' {
    BeforeEach {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Disconnect-AzDevOps
        }
    }

    It 'retrieves settings without module connection state' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $payload = @{ dataProviders = @{ 'ms.vss-build-web.pipelines-org-settings-data-provider' = @{ statusBadgesArePrivate = $true; enableShellTasksArgsSanitizing = $true } } } | ConvertTo-Json -Depth 10
            Mock Invoke-WebRequest { [pscustomobject]@{ Content = $payload; RawContent = $payload } }

            $settings = Read-AdoOrganizationPipelinesSettings -Organization fixture-org -AccessToken 'Bearer fixture-token'

            $settings.statusBadgesArePrivate | Should -BeTrue
            $settings.enableShellTasksArgsSanitizing | Should -BeTrue
            Assert-MockCalled Invoke-WebRequest -Times 1 -Exactly
        }
    }

    It 'reports an authentication response as a retrieval failure' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Mock Invoke-WebRequest { [pscustomobject]@{ Content = '<html>Sign In</html>'; RawContent = 'Sign In' } }

            { Read-AdoOrganizationPipelinesSettings -Organization fixture-org -AccessToken 'Bearer expired-token' } | Should -Throw '*Failed to retrieve pipeline settings*'
            Assert-MockCalled Invoke-WebRequest -Times 1 -Exactly
        }
    }
}

AfterAll {
    Remove-Module DevOpsTools.AzureDevOps.PSRule -Force
}
