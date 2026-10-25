BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Supported repository security evidence' -Tag Unit {
    BeforeEach {
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod { [pscustomobject]@{ value = @() } }
        Connect-AzDevOps -Organization fixture-org -PAT fixture-token
    }

    It 'preserves the rule contract when Code Security is <CodeEnabled> and Secret Protection is <SecretEnabled>' -ForEach @(
        @{ CodeEnabled = $true; SecretEnabled = $true; Expected = $true }
        @{ CodeEnabled = $false; SecretEnabled = $true; Expected = $false }
        @{ CodeEnabled = $true; SecretEnabled = $false; Expected = $false }
        @{ CodeEnabled = $false; SecretEnabled = $false; Expected = $false }
    ) {
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod {
            [pscustomobject]@{ codeSecurityFeatures = @{ codeSecurityEnabled = $CodeEnabled }; secretProtectionFeatures = @{ secretProtectionEnabled = $SecretEnabled; blockPushes = $false } }
        }
        $settings = Get-AzDevOpsRepositoryGhas -ProjectId project -RepositoryId repo
        $settings.advSecEnabled | Should -Be $Expected
        $settings.blockPushes | Should -BeFalse
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod -Exactly -Times 1 -ParameterFilter { $Uri -eq 'https://advsec.dev.azure.com/fixture-org/project/_apis/management/repositories/repo/enablement?includeAllProperties=true&api-version=7.2-preview.3' -and $Method -eq 'Get' }
    }

    It 'does not invent evidence for missing security features' {
        $settings = Get-AzDevOpsRepositoryGhas -ProjectId project -RepositoryId repo
        $settings.advSecEnabled | Should -BeNullOrEmpty
        $settings.blockPushes | Should -BeNullOrEmpty
    }
    It 'does not coerce malformed feature flags or count them as complete collection' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Mock Invoke-RestMethod {
                [pscustomobject]@{ codeSecurityFeatures = @{ codeSecurityEnabled = 'false' }; secretProtectionFeatures = @{ secretProtectionEnabled = $true; blockPushes = 'true' } }
            }
            $script:collectionStatus = [ordered]@{ Status = 'Completed'; ReasonCodes = @() }
            try {
                $settings = Get-AzDevOpsRepositoryGhas -ProjectId project -RepositoryId repo
                $settings.advSecEnabled | Should -BeNullOrEmpty
                $settings.blockPushes | Should -BeNullOrEmpty
                $script:collectionStatus.Status | Should -Be Partial
                $script:collectionStatus.ReasonCodes | Should -Contain MissingRequiredData
            } finally { $script:collectionStatus = $null }
        }
    }

    It 'retains the <Profile> permission restriction without requesting security data' -ForEach @(
        @{ Profile = 'ReadOnly' }, @{ Profile = 'FineGrained' }
    ) {
        Connect-AzDevOps -Organization fixture-org -PAT fixture-token -TokenType $Profile
        $settings = Get-AzDevOpsRepositoryGhas -ProjectId project -RepositoryId repo -WarningAction SilentlyContinue
        $settings | Should -BeNullOrEmpty
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod -Exactly -Times 0 -ParameterFilter { $Uri -match 'advsec|HierarchyQuery' }
    }

    It 'does not fall back to portal evidence when the security API rejects access' {
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod { throw 'Security evidence unavailable.' } -ParameterFilter { $Uri -like 'https://advsec.dev.azure.com/*' }
        { Get-AzDevOpsRepositoryGhas -ProjectId project -RepositoryId repo } | Should -Throw 'Security evidence unavailable.'
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod -Exactly -Times 0 -ParameterFilter { $Uri -like '*HierarchyQuery*' }
    }

}
