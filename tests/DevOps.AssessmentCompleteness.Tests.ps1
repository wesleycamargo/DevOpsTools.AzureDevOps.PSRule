BeforeAll {
    Import-Module "$PSScriptRoot/../src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psd1" -Force
    $exportCommands = @(
        'Export-AzDevOpsProject', 'Export-AzDevOpsReposAndBranchPolicies',
        'Export-AzDevOpsEnvironmentChecks', 'Export-AzDevOpsServiceConnections',
        'Export-AzDevOpsPipelines', 'Export-AzDevOpsPipelinesSettings',
        'Export-AzDevOpsVariableGroups', 'Export-AzDevOpsReleaseDefinitions',
        'Export-AzDevOpsGroups', 'Export-AzDevOpsRetentionSettings',
        'Export-AdoOrganizationPipelinesSettings', 'Export-AdoOrganizationGeneralOverview',
        'Export-AdoOrganizationGeneralBillingSettings', 'Export-AdoOrganizationSecurityPolicies'
    )
    $unmockedCommands = @()
}

Describe 'Assessment collection completeness' -Tag 'Unit' {
    BeforeEach {
        Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod { [pscustomobject]@{ value = @() } }
        Connect-AzDevOps -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111' -PAT fixture-secret
        foreach ($command in $exportCommands) {
            if ($command -in $unmockedCommands) { continue }
            Mock -ModuleName PSRule.Rules.AzureDevOps $command {
                if ($PassThru) { [pscustomobject]@{ ObjectType = 'fixture'; ObjectName = 'fixture-target' } }
            }
        }
        $testPath = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $outputPath = Join-Path $testPath 'targets'
        New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
        $reportPath = Join-Path $testPath 'completeness.json'
    }

    It 'writes completeness separately while preserving PassThru targets' {
        $targets = @(Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -PassThru -CompletenessReportPath $reportPath)

        $targets.Count | Should -Be 14
        @($targets | Where-Object ObjectType -NE 'fixture').Count | Should -Be 0
        $report = Get-Content -Raw $reportPath | ConvertFrom-Json
        $report.SchemaVersion | Should -Be 1
        $report.Organization | Should -Be 'fixture-org'
        $report.Status | Should -Be 'Complete'
        $report.Projects.Count | Should -Be 1
        $report.Projects[0].Project | Should -Be 'fixture-project'
        $report.Projects[0].Collectors.Count | Should -Be 10
        $report.OrganizationCollection.Collectors.Count | Should -Be 4
        @($report.Projects[0].Collectors | Where-Object Status -NE 'Completed').Count | Should -Be 0
        Get-ChildItem $outputPath | Should -BeNullOrEmpty
    }

    It 'records multiple failures separately and preserves successful targets' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Export-AzDevOpsReposAndBranchPolicies { throw 'fixture-secret must not appear in the report' }
        Mock -ModuleName PSRule.Rules.AzureDevOps Export-AzDevOpsPipelines { throw 'Bearer fixture-secret' }

        $targets = @(Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -PassThru -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue 3>$null)

        $targets.Count | Should -Be 12
        $report = Get-Content -Raw $reportPath | ConvertFrom-Json
        $report.Status | Should -Be 'Partial'
        $failed = @($report.Projects[0].Collectors | Where-Object Status -EQ 'Failed')
        $failed.Count | Should -Be 2
        $failed.Command | Should -Contain 'Export-AzDevOpsReposAndBranchPolicies'
        $failed.Command | Should -Contain 'Export-AzDevOpsPipelines'
        (Get-Content -Raw $reportPath) | Should -Not -Match 'fixture-secret|Bearer|Authorization|Exception'
        Should -Invoke -ModuleName PSRule.Rules.AzureDevOps Export-AdoOrganizationSecurityPolicies -Times 1 -Exactly
    }

    It 'writes the report and attempts every collector before strict mode fails' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Export-AzDevOpsProject { throw 'failed' }

        { Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue 3>$null } | Should -Throw '*collection is incomplete*'

        (Get-Content -Raw $reportPath | ConvertFrom-Json).Status | Should -Be 'Partial'
        Should -Invoke -ModuleName PSRule.Rules.AzureDevOps Export-AdoOrganizationSecurityPolicies -Times 1 -Exactly
    }

    It 'names incomplete collectors with terminating error handling for <Scope> exports' -TestCases @(
        @{ Scope = 'project' },
        @{ Scope = 'organization' }
    ) {
        param ($Scope)
        Mock -ModuleName PSRule.Rules.AzureDevOps Export-AzDevOpsProject {
            throw 'fixture collector failure'
        }
        Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsProject { [pscustomobject]@{ name = 'fixture-project' } }

        $export = if ($Scope -eq 'project') { 'Export-AzDevOpsRuleData' } else { 'Export-AzDevOpsOrganizationRuleData' }
        $parameters = @{ Organization = 'fixture-org'; OrganizationId = '11111111-1111-1111-1111-111111111111' }
        if ($Scope -eq 'project') { $parameters.Project = 'fixture-project' }

        { & $export @parameters -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath -ErrorAction Stop } |
            Should -Throw '*collection is incomplete: Export-AzDevOpsProject.*'

        (Get-Content -Raw $reportPath | ConvertFrom-Json).Status | Should -Be 'Partial'
    }

    It 'keeps exception credentials out of aggregate error diagnostics' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Export-AzDevOpsProject { throw 'Bearer fixture-secret' }

        $diagnostics = @(Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath $reportPath 2>&1 3>$null)

        $errors = @($diagnostics | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
        $errors.Count | Should -BeGreaterThan 0
        ($errors | Out-String) | Should -Not -Match 'Bearer|fixture-secret'
        (Get-Content -Raw $reportPath) | Should -Not -Match 'Bearer|fixture-secret'
    }

    It 'reports unavailable coverage when every collector fails' {
        foreach ($command in $exportCommands) { Mock -ModuleName PSRule.Rules.AzureDevOps $command { throw 'failed' } }

        Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue 3>$null

        (Get-Content -Raw $reportPath | ConvertFrom-Json).Status | Should -Be 'Unavailable'
    }

    It 'keeps file output and default invocation free of status records' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Export-AzDevOpsProject {
            '{"ObjectType":"fixture","ObjectName":"file-target"}' | Set-Content (Join-Path $OutputPath 'fixture.ado.json')
        }

        $result = @(Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath)

        $result.Count | Should -Be 0
        (Get-Content -Raw (Join-Path $outputPath 'fixture.ado.json') | ConvertFrom-Json).ObjectName | Should -Be 'file-target'
        Test-Path $reportPath | Should -BeFalse
    }

    It 'rejects a completeness report inside the target directory before exporting' {
        { Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath (Join-Path $outputPath 'report.json') } | Should -Throw '*outside*'
        Should -Invoke -ModuleName PSRule.Rules.AzureDevOps Export-AzDevOpsProject -Times 0 -Exactly
    }

    It 'fails when the report cannot be written' {
        { Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath (Join-Path $TestDrive 'missing/report.json') } | Should -Throw
        Should -Invoke -ModuleName PSRule.Rules.AzureDevOps Export-AdoOrganizationSecurityPolicies -Times 1 -Exactly
    }

    It 'does not carry collection failure into the next invocation' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Export-AzDevOpsProject { throw 'failed' }
        Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue 3>$null
        Mock -ModuleName PSRule.Rules.AzureDevOps Export-AzDevOpsProject { }

        Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath $reportPath -Strict

        (Get-Content -Raw $reportPath | ConvertFrom-Json).Status | Should -Be 'Complete'
    }

    It 'attempts every project and writes one report before organization strict mode fails' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsProject {
            @([pscustomobject]@{ name = 'first-project' }, [pscustomobject]@{ name = 'second-project' })
        }
        Mock -ModuleName PSRule.Rules.AzureDevOps Export-AzDevOpsProject -ParameterFilter { $Project -eq 'first-project' } { throw 'failed' }

        { Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111' -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue 3>$null } | Should -Throw '*collection is incomplete*'

        $report = Get-Content -Raw $reportPath | ConvertFrom-Json
        $report.Projects.Count | Should -Be 2
        $report.Projects[0].Status | Should -Be 'Partial'
        $report.Projects[1].Status | Should -Be 'Complete'
        Should -Invoke -ModuleName PSRule.Rules.AzureDevOps Export-AdoOrganizationSecurityPolicies -Times 1 -Exactly
    }

    It 'treats an organization with no projects as complete and empty' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsProject { @() }

        Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111' -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath

        $report = Get-Content -Raw $reportPath | ConvertFrom-Json
        $report.Status | Should -Be 'Complete'
        $report.ProjectDiscovery.Status | Should -Be 'Empty'
        $report.Projects.Count | Should -Be 0
        $report.OrganizationCollection.Collectors.Count | Should -Be 4
        Should -Invoke -ModuleName PSRule.Rules.AzureDevOps Export-AdoOrganizationSecurityPolicies -Times 1 -Exactly
    }

    It 'fails strict organization collection when there are no projects and organization evidence is unavailable' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsProject { @() }
        Mock -ModuleName PSRule.Rules.AzureDevOps Export-AdoOrganizationSecurityPolicies { throw 'denied' }
        { Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId org-id -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue 3>$null } | Should -Throw '*collection is incomplete*'
        $report = Get-Content $reportPath -Raw | ConvertFrom-Json
        $report.OrganizationCollection.Status | Should -Be Partial
        $report.Status | Should -Be Partial
    }

    It 'refreshes organization authentication after project collection changes the token' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Export-AzDevOpsProject {
            InModuleScope PSRule.Rules.AzureDevOps { $script:connection.Token = 'Bearer refreshed-token' }
        }
        Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -Strict
        Should -Invoke -ModuleName PSRule.Rules.AzureDevOps Export-AdoOrganizationSecurityPolicies -Times 1 -Exactly -ParameterFilter { $AccessToken -eq 'Bearer refreshed-token' }
    }

    It 'recognizes the real empty project-list response' {
        Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111' -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath

        $report = Get-Content -Raw $reportPath | ConvertFrom-Json
        $report.ProjectDiscovery.Status | Should -Be 'Empty'
        $report.Projects.Count | Should -Be 0
    }

    It 'rejects malformed project discovery rather than claiming an empty organization' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod { [pscustomobject]@{} }

        { Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111' -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue } | Should -Throw '*collection is incomplete*'

        $report = Get-Content -Raw $reportPath | ConvertFrom-Json
        $report.ProjectDiscovery.Status | Should -Be 'Failed'
        $report.ProjectDiscovery.ReasonCodes | Should -Contain 'ProjectDiscoveryFailed'
        $report.Projects.Count | Should -Be 0
    }

    It 'reports failed project discovery without claiming an empty organization' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsProject { throw 'fixture-secret' }

        { Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111' -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue } | Should -Throw '*collection is incomplete*'

        $report = Get-Content -Raw $reportPath | ConvertFrom-Json
        $report.Status | Should -Be 'Partial'
        $report.ProjectDiscovery.Status | Should -Be 'Failed'
        (Get-Content -Raw $reportPath) | Should -Not -Match 'fixture-secret'
    }

    It 'writes an incomplete report and rejects a failed later discovery page in strict mode' {
        Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-AzDevOpsRestPage {
            [pscustomobject]@{ Body = [pscustomobject]@{ value = @([pscustomobject]@{ name = 'first-project' }) }; Headers = @{ 'x-ms-continuationtoken' = 'next' } }
        } -ParameterFilter { $Uri -notmatch 'continuationToken=' }
        Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-AzDevOpsRestPage { throw 'later page unavailable' } -ParameterFilter { $Uri -match 'continuationToken=' }
        { Export-AzDevOpsOrganizationRuleData -Organization fixture-org -OrganizationId org-id -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue } | Should -Throw '*collection is incomplete*'
        $report = Get-Content $reportPath -Raw | ConvertFrom-Json
        $report.Status | Should -Not -Be Complete
        $report.ProjectDiscovery.Status | Should -Be Failed
        Should -Invoke -ModuleName PSRule.Rules.AzureDevOps Invoke-AzDevOpsRestPage -Times 1 -Exactly -ParameterFilter { $Uri -match 'continuationToken=' }
    }

    Context 'Real collection paths' {
        BeforeAll {
            $unmockedCommands = @(
                'Export-AzDevOpsReposAndBranchPolicies', 'Export-AzDevOpsEnvironmentChecks', 'Export-AzDevOpsPipelines',
                'Export-AzDevOpsServiceConnections', 'Export-AzDevOpsVariableGroups', 'Export-AzDevOpsReleaseDefinitions', 'Export-AzDevOpsGroups'
            )
        }

        BeforeEach {
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepos { @() }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsEnvironments { @() }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsPipelines { @() }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsPipelineAcls { @{} }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsServiceConnections { @() }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsVariableGroups { @() }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsReleaseDefinitions { @() }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsGroups { @() }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsProject -ParameterFilter { $Project } { [pscustomobject]@{ id = 'project-id'; name = 'fixture-project' } }
        }

        It 'records legitimate empty collections as complete in both output modes' -ForEach @(@{ pass = $true }, @{ pass = $false }) {
            Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -PassThru:$pass -Strict -CompletenessReportPath $reportPath | Out-Null

            $report = Get-Content -Raw $reportPath | ConvertFrom-Json
            $report.Status | Should -Be 'Complete'
            @($report.Projects[0].Collectors | Where-Object Status -EQ 'Empty').Count | Should -Be 7
        }

        It 'reports permission-unavailable environments and rejects them in strict mode' {
            Connect-AzDevOps -Organization fixture-org -PAT fixture-secret -TokenType ReadOnly

            { Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath 3>$null } | Should -Throw '*collection is incomplete*'

            $record = (Get-Content -Raw $reportPath | ConvertFrom-Json).Projects[0].Collectors | Where-Object Command -EQ 'Export-AzDevOpsEnvironmentChecks'
            $record.Status | Should -Be 'Unavailable'
            $record.ReasonCodes | Should -Contain 'PermissionDenied'
        }

        It 'reports unavailable YAML while retaining the pipeline target' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsPipelines {
                [pscustomobject]@{ id = 1; name = 'fixture-pipeline'; folder = '\'; _links = @{ web = @{ href = 'https://dev.azure.com/org/project/_build' } }; configuration = @{ type = 'yaml'; repository = @{ type = 'azureReposGit' } } }
            }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsPipelineYaml { $null }

            $targets = @(Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -PassThru -CompletenessReportPath $reportPath 3>$null)

            @($targets | Where-Object ObjectType -EQ 'Azure.DevOps.Pipeline').Count | Should -Be 1
            $record = (Get-Content -Raw $reportPath | ConvertFrom-Json).Projects[0].Collectors | Where-Object Command -EQ 'Export-AzDevOpsPipelines'
            $record.Status | Should -Be 'Partial'
            $record.ReasonCodes | Should -Contain 'YamlUnavailable'
        }

        It 'keeps mixed YAML and object output unchanged when collection is complete' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsPipelines {
                [pscustomobject]@{ id = 1; name = 'fixture-pipeline'; folder = '\'; _links = @{ web = @{ href = 'https://dev.azure.com/org/project/_build' } }; configuration = @{ type = 'yaml'; repository = @{ type = 'azureReposGit' } } }
            }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsPipelineYaml { "trigger: none`nsteps: []" }

            $targets = @(Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -PassThru -CompletenessReportPath $reportPath -Strict)

            $yaml = @($targets | Where-Object { $_ -is [string] })
            $yaml.Count | Should -Be 1
            $yaml[0] | Should -Match 'ObjectType: Azure.DevOps.Pipelines.PipelineYaml'
            @($targets | Where-Object ObjectType -EQ 'Azure.DevOps.Pipeline').Count | Should -Be 1
        }

        It 'treats a repository without a default branch as collected data' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepos { [pscustomobject]@{ id = 'repo-id'; name = 'empty-repo'; defaultBranch = $null; project = @{ id = 'project-id' } } }
            Mock -ModuleName PSRule.Rules.AzureDevOps Test-AzDevOpsFileExists { $false }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsBranches { @() }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepositoryGhas { @{ isEnabled = $false } }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepositoryPipelinePermissions { @{} }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepositoryAcls { @{} }

            $targets = @(Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -PassThru -Strict -CompletenessReportPath $reportPath)

            @($targets | Where-Object ObjectType -EQ 'Azure.DevOps.Repo').Count | Should -Be 1
            (Get-Content -Raw $reportPath | ConvertFrom-Json).Status | Should -Be 'Complete'
        }

        It 'reports omitted repository enrichment as partial rather than complete' {
            Connect-AzDevOps -Organization fixture-org -PAT fixture-secret -TokenType ReadOnly
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepos { [pscustomobject]@{ id = 'repo-id'; name = 'fixture-repo'; defaultBranch = $null; project = @{ id = 'project-id' } } }
            Mock -ModuleName PSRule.Rules.AzureDevOps Test-AzDevOpsFileExists { $false }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsBranches { @() }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepositoryPipelinePermissions { @{} }

            Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath $reportPath 3>$null

            $record = (Get-Content -Raw $reportPath | ConvertFrom-Json).Projects[0].Collectors | Where-Object Command -EQ 'Export-AzDevOpsReposAndBranchPolicies'
            $record.Status | Should -Be 'Partial'
            $record.ReasonCodes | Should -Contain 'PermissionDenied'
        }

        It 'reports a malformed repository ACL response as partial' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepos { [pscustomobject]@{ id = 'repo-id'; name = 'fixture-repo'; defaultBranch = $null; project = @{ id = 'project-id' } } }
            Mock -ModuleName PSRule.Rules.AzureDevOps Test-AzDevOpsFileExists { $false }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsBranches { @() }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepositoryGhas { @{ isEnabled = $false } }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepositoryPipelinePermissions { @{} }
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod -ParameterFilter { $Uri -like '*accesscontrollists*' } { [pscustomobject]@{} }

            Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath $reportPath 3>$null

            $record = (Get-Content -Raw $reportPath | ConvertFrom-Json).Projects[0].Collectors | Where-Object Command -EQ 'Export-AzDevOpsReposAndBranchPolicies'
            $record.Status | Should -Be 'Partial'
            $record.ReasonCodes | Should -Contain 'MissingRequiredData'
        }

        It 'distinguishes a missing branch-policy response from a valid empty policy list' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepos { [pscustomobject]@{ id = 'repo-id'; name = 'fixture-repo'; defaultBranch = 'refs/heads/main'; project = @{ id = 'project-id' } } }
            Mock -ModuleName PSRule.Rules.AzureDevOps Test-AzDevOpsFileExists { $false }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsBranches { @() }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepositoryGhas { @{ isEnabled = $false } }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepositoryPipelinePermissions { @{} }
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsRepositoryAcls { @{} }
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod -ParameterFilter { $Uri -like '*policy/configurations*' } { [pscustomobject]@{} }

            Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue 3>$null

            $record = (Get-Content -Raw $reportPath | ConvertFrom-Json).Projects[0].Collectors | Where-Object Command -EQ 'Export-AzDevOpsReposAndBranchPolicies'
            $record.Status | Should -Be 'Failed'
            $record.ReasonCodes | Should -Contain 'MissingRequiredData'
        }
    }

    Context 'Organization response validation' {
        BeforeAll { $unmockedCommands = @('Export-AdoOrganizationPipelinesSettings') }

        It 'marks a missing provider unavailable rather than successful or empty' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-WebRequest {
                [pscustomobject]@{ Content = '{"dataProviders":{}}'; RawContent = '{}' }
            }

            { Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue 3>$null } | Should -Throw '*collection is incomplete*'

            $record = (Get-Content -Raw $reportPath | ConvertFrom-Json).OrganizationCollection.Collectors | Where-Object Command -EQ 'Export-AdoOrganizationPipelinesSettings'
            $record.Status | Should -Be 'Unavailable'
            $record.ReasonCodes | Should -Contain 'MissingRequiredData'
        }

        It 'marks missing settings partial while preserving valid false settings' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-WebRequest {
                [pscustomobject]@{ Content = '{"dataProviders":{"ms.vss-build-web.pipelines-org-settings-data-provider":{"statusBadgesArePrivate":false}}}'; RawContent = '{}' }
            }

            $targets = @(Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -PassThru -CompletenessReportPath $reportPath)

            ($targets | Where-Object ObjectType -EQ 'Azure.DevOps.Organization.Pipelines.Settings').statusBadgesArePrivate | Should -BeFalse
            $record = (Get-Content -Raw $reportPath | ConvertFrom-Json).OrganizationCollection.Collectors | Where-Object Command -EQ 'Export-AdoOrganizationPipelinesSettings'
            $record.Status | Should -Be 'Partial'
            $record.ReasonCodes | Should -Contain 'MissingRequiredData'
        }

        It 'classifies supplied settings as <expected> without treating false as absent' -ForEach @(
            @{ nullSetting = $false; expected = 'Complete'; strict = $true },
            @{ nullSetting = $true; expected = 'Partial'; strict = $false }
        ) {
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-WebRequest {
                $settings = @{}
                foreach ($name in @(
                    'statusBadgesArePrivate', 'enforceSettableVar', 'enforceJobAuthScope', 'enforceJobAuthScopeForReleases',
                    'enforceReferencedRepoScopedToken', 'disableStageChooser', 'disableClassicBuildPipelineCreation',
                    'disableClassicReleasePipelineCreation', 'disableInBoxTasksVar', 'disableMarketplaceTasksVar',
                    'disableNode6TasksVar', 'enableShellTasksArgsSanitizing', 'forkProtectionEnabled', 'buildsEnabledForForks',
                    'enforceJobAuthScopeForForks', 'enforceNoAccessToSecretsFromForks', 'disableImpliedYAMLCiTrigger',
                    'auditEnforceSettableVar', 'isTaskLockdownFeatureEnabled', 'hasManagePipelinePoliciesPermission',
                    'isCommentRequiredForPullRequest', 'requireCommentsForNonTeamMembersOnly',
                    'requireCommentsForNonTeamMemberAndNonContributors', 'enableShellTasksArgsSanitizingAudit'
                )) { $settings[$name] = $false }
                if ($nullSetting) { $settings.statusBadgesArePrivate = $null }
                $json = @{ dataProviders = @{ 'ms.vss-build-web.pipelines-org-settings-data-provider' = $settings } } | ConvertTo-Json -Depth 5
                [pscustomobject]@{ Content = $json; RawContent = $json }
            }

            Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -Strict:$strict -CompletenessReportPath $reportPath 3>$null

            (Get-Content -Raw $reportPath | ConvertFrom-Json).Status | Should -Be $expected
        }
    }

    Context 'Billing response validation' {
        BeforeAll { $unmockedCommands = @('Export-AdoOrganizationGeneralBillingSettings') }

        It 'accepts unconfigured billing with false flags and a null subscription' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-WebRequest {
                [pscustomobject]@{ Content = '{"currentOrganizationName":"fixture-org","subscriptionStatus":null,"subscriptionId":null,"isEnterpriseBillingEnabled":false,"isAssignmentBillingEnabled":false}'; RawContent = '{}' }
            }

            $targets = @(Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -PassThru -CompletenessReportPath $reportPath -Strict)

            ($targets | Where-Object ObjectType -EQ 'Azure.DevOps.Organization.GeneralBillingSettings').isEnterpriseBillingEnabled | Should -BeFalse
            (Get-Content -Raw $reportPath | ConvertFrom-Json).Status | Should -Be 'Complete'
        }

        It 'reports absent billing data as unavailable' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-WebRequest { [pscustomobject]@{ Content = 'null'; RawContent = 'null' } }

            { Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue } | Should -Throw '*collection is incomplete*'

            $record = (Get-Content -Raw $reportPath | ConvertFrom-Json).OrganizationCollection.Collectors | Where-Object Command -EQ 'Export-AdoOrganizationGeneralBillingSettings'
            $record.Status | Should -Be 'Unavailable'
        }
    }

    Context 'Security policy response validation' {
        BeforeAll { $unmockedCommands = @('Export-AdoOrganizationSecurityPolicies') }

        It 'accepts complete security policy identifiers in <Naming> form' -ForEach @(
            @{ Naming = 'API'; Spaced = $false }
            @{ Naming = 'legacy spaced'; Spaced = $true }
        ) {
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-WebRequest {
                $names = @('Disallow Secure Shell', 'Allow Request Access Token', 'Allow Team Admins Invitations Access Token', 'Allow Feedback Collection', 'Enforce AAD Conditional Access', 'Disallow OAuth Authentication', 'Log Audit Events', 'Artifacts External Package Protection Token', 'Allow Anonymous Access', 'Disallow Aad Guest User Access')
                $entries = foreach ($name in $names) {
                    if (-not $Spaced) { $name = $name -replace '\s+', '' }
                    @{ policy = @{ name = "Policy.$name"; effectiveValue = $false }; description = 'fixture' }
                }
                $json = @{ fps = @{ dataProviders = @{ data = @{ 'ms.vss-admin-web.organization-policies-data-provider' = @{ policies = @{ fixture = @($entries) } } } } } } | ConvertTo-Json -Depth 10
                [pscustomobject]@{ Content = $json; RawContent = $json }
            }

            $targets = @(Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -PassThru -CompletenessReportPath $reportPath -Strict)

            ($targets | Where-Object ObjectType -EQ 'Azure.DevOps.Organization.Security.Policies').'policy.disallowSecureShell' | Should -BeFalse
            (Get-Content -Raw $reportPath | ConvertFrom-Json).Status | Should -Be 'Complete'
            (Get-Content -Raw $reportPath | ConvertFrom-Json).OrganizationCollection.Status | Should -Be 'Complete'
        }

        It 'reports a missing security provider as unavailable' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-WebRequest { [pscustomobject]@{ Content = '{"fps":{"dataProviders":{"data":{}}}}'; RawContent = '{}' } }

            { Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -Strict -CompletenessReportPath $reportPath -ErrorAction SilentlyContinue } | Should -Throw '*collection is incomplete*'

            $record = (Get-Content -Raw $reportPath | ConvertFrom-Json).OrganizationCollection.Collectors | Where-Object Command -EQ 'Export-AdoOrganizationSecurityPolicies'
            $record.Status | Should -Be 'Unavailable'
        }

        It 'reports missing required security policies as partial while retaining collected policies' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-WebRequest {
                $json = @{ fps = @{ dataProviders = @{ data = @{ 'ms.vss-admin-web.organization-policies-data-provider' = @{ policies = @{ fixture = @(@{ policy = @{ name = 'Policy.Disallow Secure Shell'; effectiveValue = $false }; description = 'fixture' }) } } } } } } | ConvertTo-Json -Depth 10
                [pscustomobject]@{ Content = $json; RawContent = $json }
            }

            $targets = @(Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -PassThru -CompletenessReportPath $reportPath 3>$null)

            ($targets | Where-Object ObjectType -EQ 'Azure.DevOps.Organization.Security.Policies').'policy.disallowSecureShell' | Should -BeFalse
            $record = (Get-Content -Raw $reportPath | ConvertFrom-Json).OrganizationCollection.Collectors | Where-Object Command -EQ 'Export-AdoOrganizationSecurityPolicies'
            $record.Status | Should -Be 'Partial'
        }
    }

    Context 'Overview response validation' {
        BeforeAll { $unmockedCommands = @('Export-AdoOrganizationGeneralOverview') }

        It 'accepts a present but unset description' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-WebRequest {
                $json = @{ fps = @{ dataProviders = @{ data = @{
                    'ms.vss-admin-web.organization-admin-overview-data-provider' = @{ description = $null; timeZone = @{ displayName = 'UTC' }; geography = 'Europe'; region = 'region' }
                    'ms.vss-web.page-data' = @{ user = @{ displayName = 'Fixture Owner' } }
                } } } } | ConvertTo-Json -Depth 10
                [pscustomobject]@{ Content = $json; RawContent = $json }
            }

            Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath $reportPath -Strict

            (Get-Content -Raw $reportPath | ConvertFrom-Json).Status | Should -Be 'Complete'
        }

        It 'reports a missing overview provider as unavailable' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-WebRequest { [pscustomobject]@{ Content = '{"fps":{"dataProviders":{"data":{}}}}'; RawContent = '{}' } }

            { Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath $reportPath -Strict } | Should -Throw '*collection is incomplete*'

            $record = (Get-Content -Raw $reportPath | ConvertFrom-Json).OrganizationCollection.Collectors | Where-Object Command -EQ 'Export-AdoOrganizationGeneralOverview'
            $record.Status | Should -Be 'Unavailable'
        }
    }

    Context 'Project setting response validation' {
        BeforeAll { $unmockedCommands = @('Export-AzDevOpsPipelinesSettings', 'Export-AzDevOpsRetentionSettings') }

        It 'rejects missing required project settings and retention fields' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod { [pscustomobject]@{} }

            { Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath $reportPath -Strict } | Should -Throw '*collection is incomplete*'

            $report = Get-Content -Raw $reportPath | ConvertFrom-Json
            foreach ($command in @('Export-AzDevOpsPipelinesSettings', 'Export-AzDevOpsRetentionSettings')) {
                $record = $report.Projects[0].Collectors | Where-Object Command -EQ $command
                $record.Status | Should -Not -Be 'Completed'
                $record.ReasonCodes | Should -Contain 'MissingRequiredData'
            }
        }

        It 'accepts collected false settings and zero retention values' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod {
                if ($Uri -like '*generalsettings*') {
                    [pscustomobject]@{
                        enforceSettableVar = $false; enforceJobAuthScope = $false; enforceJobAuthScopeForReleases = $false
                        enforceReferencedRepoScopedToken = $false; isCommentRequiredForPullRequest = $false
                        enforceNoAccessToSecretsFromForks = $false; enableShellTasksArgsSanitizing = $false; statusBadgesArePrivate = $false
                    }
                } elseif ($Uri -like '*build/retention*') {
                    [pscustomobject]@{ purgeArtifacts = @{ value = 0 }; purgePullRequestRuns = @{ value = 0 } }
                } else { [pscustomobject]@{} }
            }

            Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -CompletenessReportPath $reportPath -Strict

            (Get-Content -Raw $reportPath | ConvertFrom-Json).Status | Should -Be 'Complete'
        }
    }

    Context 'Malformed pipeline enrichment' {
        BeforeAll { $unmockedCommands = @('Export-AzDevOpsPipelines') }

        It 'retains the pipeline and reports missing ACL data as partial' {
            Mock -ModuleName PSRule.Rules.AzureDevOps Get-AzDevOpsPipelines {
                [pscustomobject]@{ id = 1; name = 'fixture-pipeline'; folder = '\'; _links = @{ web = @{ href = 'https://dev.azure.com/org/project/_build' } }; configuration = @{ type = 'designerJson' } }
            }
            Mock -ModuleName PSRule.Rules.AzureDevOps Invoke-RestMethod -ParameterFilter { $Uri -like '*accesscontrollists*' } { [pscustomobject]@{} }

            $targets = @(Export-AzDevOpsRuleData -Project fixture-project -OutputPath $outputPath -PassThru -CompletenessReportPath $reportPath 3>$null)

            @($targets | Where-Object ObjectType -EQ 'Azure.DevOps.Pipeline').Count | Should -Be 1
            $record = (Get-Content -Raw $reportPath | ConvertFrom-Json).Projects[0].Collectors | Where-Object Command -EQ 'Export-AzDevOpsPipelines'
            $record.Status | Should -Be 'Partial'
            $record.ReasonCodes | Should -Contain 'MissingRequiredData'
        }
    }
}

AfterAll {
    Disconnect-AzDevOps
    Remove-Module PSRule.Rules.AzureDevOps -Force
}
