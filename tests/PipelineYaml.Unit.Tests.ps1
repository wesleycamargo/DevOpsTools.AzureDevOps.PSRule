BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Get-AzDevOpsPipelineYaml raw YAML fallback' -Tag 'Unit' {
    BeforeAll {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $script:connection = [pscustomobject]@{ Organization = 'org' } |
                Add-Member -MemberType ScriptMethod -Name GetHeader -Value { @{} } -PassThru
        }
        # The preview fails, so the function falls back to the pipeline definition and the raw file.
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod -ParameterFilter { $Method -eq 'POST' } { throw 'preview failed' }
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod -ParameterFilter { $Uri -like '*/_apis/pipelines/*' -and $Method -eq 'Get' } {
            [pscustomobject]@{ configuration = @{ repository = @{ id = 'repo' }; path = '/azure-pipelines.yml' } }
        }
    }

    AfterAll {
        Disconnect-AzDevOps
    }

    It 'returns the raw YAML text' {
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod -ParameterFilter { $Uri -like '*/items?*' } { "trigger: none`nsteps: []" }

        Get-AzDevOpsPipelineYaml -PipelineId 1 -Project 'project' 3>$null | Should -Match '^trigger: none'
    }

    It 'returns nothing and warns when the raw file request returns a sign-in page' {
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod -ParameterFilter { $Uri -like '*/items?*' } { '<!DOCTYPE html><html>Sign In</html>' }

        $yaml = Get-AzDevOpsPipelineYaml -PipelineId 1 -Project 'project' -WarningVariable warning 3>$null

        $yaml | Should -BeNullOrEmpty
        $warning | Should -Not -BeNullOrEmpty
    }
}
