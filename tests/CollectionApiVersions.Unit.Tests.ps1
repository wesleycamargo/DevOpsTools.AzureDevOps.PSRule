BeforeAll {
    Import-Module "$PSScriptRoot/../src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psd1" -Force
}

Describe 'Versioned collection API contracts' -Tag Unit {
    BeforeEach {
        Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod { [pscustomobject]@{ value = @() } }
        Connect-AzDevOps -Organization fixture-org -PAT fixture-token
    }

    It 'retrieves project pipeline settings with false values through the stable API' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod { [pscustomobject]@{ statusBadgesArePrivate = $false } }
        $settings = Get-AzDevOpsPipelinesSettings -Project fixture-project
        $settings.statusBadgesArePrivate | Should -BeFalse
        Should -Invoke -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod -Exactly -Times 1 -ParameterFilter {
            $Uri -eq 'https://dev.azure.com/fixture-org/fixture-project/_apis/build/generalsettings?api-version=7.1' -and $Method -eq 'Get'
        }
    }

    It 'retrieves retention settings and policy through stable APIs' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod {
            if ($Uri -like '*build/retention*') { return [pscustomobject]@{ purgeArtifacts = @{ value = 30 }; purgePullRequestRuns = @{ value = 10 } } }
            [pscustomobject]@{ daysToKeepDeletedBuildsBeforeDestroy = 7 }
        }
        $settings = Get-AzDevOpsRetentionSettings -Project fixture-project
        $settings.RetentionSettings.purgeArtifacts.value | Should -Be 30
        $settings.RetentionPolicy.daysToKeepDeletedBuildsBeforeDestroy | Should -Be 7
        foreach ($endpoint in 'retention', 'settings') {
            Should -Invoke -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod -Exactly -Times 1 -ParameterFilter {
                $Uri -eq "https://dev.azure.com/fixture-org/fixture-project/_apis/build/$endpoint`?api-version=7.1" -and $Method -eq 'Get'
            }
        }
    }

    It 'retrieves repository pipeline authorization without changing false into missing evidence' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod { [pscustomobject]@{ allPipelines = @{ authorized = $false } } }
        $settings = Get-AzDevOpsRepositoryPipelinePermissions -ProjectId fixture-project -RepositoryId repo
        $settings.allPipelines.authorized | Should -BeFalse
        Should -Invoke -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod -Exactly -Times 1 -ParameterFilter {
            $Uri -eq 'https://dev.azure.com/fixture-org/fixture-project/_apis/pipelines/pipelinePermissions/repository/fixture-project.repo?api-version=7.1-preview.1' -and $Method -eq 'Get'
        }
    }
}
