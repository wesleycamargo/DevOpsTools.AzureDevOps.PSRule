BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Empty collection contracts with deterministic API fixtures' -Tag Unit {
    BeforeEach {
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod { [pscustomobject]@{ value = @(); count = 0 } }
        Connect-AzDevOps -Organization fixture-org -PAT fixture-token
    }

    It 'returns an empty collection for <Command>' -ForEach @(
        @{ Command = 'Get-AzDevOpsPipelines'; Parameters = @{ Project = 'fixture-project' } }
        @{ Command = 'Get-AzDevOpsEnvironments'; Parameters = @{ Project = 'fixture-project' } }
        @{ Command = 'Get-AzDevOpsReleaseDefinitions'; Parameters = @{ Project = 'fixture-project' } }
        @{ Command = 'Get-AzDevOpsVariableGroups'; Parameters = @{ Project = 'fixture-project' } }
        @{ Command = 'Get-AzDevOpsBranches'; Parameters = @{ Project = 'fixture-project'; Repository = 'empty-repo' } }
    ) {
        & $Command @Parameters | Should -BeNullOrEmpty
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod -ParameterFilter { $Uri -match '_apis/(pipelines|distributedtask|release|git)' }
    }
}
