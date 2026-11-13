BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}
Describe 'Versioned assessment run artifacts' -Tag 'Unit' {
    It 'rejects a projection with targets but no matching result provenance' {
        $directory = New-Item -Path "$TestDrive/unmatched/project" -ItemType Directory -Force
        @{ ObjectType = 'Azure.DevOps.Project'; ObjectName = 'fixture'; visibility = 'private' } | ConvertTo-Json | Set-Content "$directory/project.json"
        { Export-AzDevOpsAssessmentRun -Result @() -ExportPath "$TestDrive/unmatched" -OutputPath "$TestDrive/empty.json" -Organization fixture -SourceRevision synthetic } | Should -Throw '*no detailed rule results*'
    }
    It 'preserves raw SARIF and separates repeated organization identities by project scope' {
        $export = New-Item -Path "$TestDrive/export" -ItemType Directory
        foreach ($project in 'alpha', 'beta') {
            $directory = New-Item -Path "$export/$project" -ItemType Directory
            [pscustomobject]@{
                ObjectType = 'Azure.DevOps.Repo.Branch'; ObjectName = 'fixture.same-identity'; BranchPolicy = @()
                syntheticPayloadMustNotBePublished = 'private-fixture-payload'
            } | ConvertTo-Json -Depth 5 | Set-Content "$directory/branch.json"
            @{ ObjectType = 'Azure.DevOps.Pipeline'; ObjectName = 'fixture.missing-permissions' } | ConvertTo-Json | Set-Content "$directory/pipeline.json"
            @{ ObjectType = 'Azure.DevOps.Organization.GeneralOverview'; ObjectName = 'fixture.no-policy'; geography = 'fixture-region' } | ConvertTo-Json | Set-Content "$directory/overview.json"
        }
        $sarifPath = "$TestDrive/raw.sarif"
        $rules = 'Azure.DevOps.Repos.Branch.HasBranchPolicy', 'Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled', 'Azure.DevOps.Pipelines.Core.InheritedPermissions', 'Azure.DevOps.Organization.GeneralOverview.GeographySet'
        $null = Assert-PSRule -InputPath ($export.FullName + [IO.Path]::DirectorySeparatorChar) -Module DevOpsTools.AzureDevOps.PSRule -Name $rules -Outcome All -Culture en -OutputPath $sarifPath -OutputFormat Sarif -ResultVariable raw -ErrorAction SilentlyContinue
        $before = Get-Content $sarifPath -Raw
        $details = @(Invoke-PSRule -InputPath ($export.FullName + [IO.Path]::DirectorySeparatorChar) -Module DevOpsTools.AzureDevOps.PSRule -Name $rules -Outcome All -Culture en)
        $statusPath = Join-Path $TestDrive 'collection-status.json'
        '{"Status":"Complete"}' | Set-Content -LiteralPath $statusPath
        $htmlPath = Join-Path $TestDrive 'psrule-report.html'
        $report = Export-AzDevOpsAssessmentRun -Result $details -ExportPath $export.FullName -OutputPath "$TestDrive/assessment.json" -Organization fixture -SourceRevision synthetic-commit -HtmlOutputPath $htmlPath -CollectionStatusPath $statusPath
        $html = Get-Content -LiteralPath $htmlPath -Raw
        $html | Should -Match 'fixture/alpha'
        $html | Should -Match 'fixture/beta'
        $html | Should -Match 'Unknown'
        $html | Should -Not -Match 'private-fixture-payload|syntheticPayloadMustNotBePublished'
        $report.Projects.Count | Should -Be 2
        $report.Projects[0].ScopeId | Should -Not -Be $report.Projects[1].ScopeId
        foreach ($project in $report.Projects) {
            $project.Findings.Count | Should -Be 4
            $project.RiskObjectives.Count | Should -Be 3
            @($project.Findings | Where-Object Outcome -EQ 'Unknown').Count | Should -Be 1
            @($project.Findings | Where-Object Outcome -EQ 'NotApplicable').Count | Should -Be 1
            $project.Summary.SecurityScore | Should -BeNullOrEmpty
        }
        (Get-Content $sarifPath -Raw) | Should -Be $before
        $sarif = $before | ConvertFrom-Json
        $sarif.runs[0].results.Count | Should -Be 4
        @($sarif.runs[0].results.rule.id | Sort-Object -Unique).Count | Should -Be 2
        $serialized = Get-Content "$TestDrive/assessment.json" -Raw
        $serialized | Should -Not -Match 'private-fixture-payload|syntheticPayloadMustNotBePublished'
        $report.RuleSetVersion | Should -Be (Get-AzDevOpsAssessmentCatalog).RuleSetVersion
        $report.SeverityPolicyVersion | Should -Be '1.1.0'
        $report.SourceRevision | Should -Be 'synthetic-commit'
    }
    It 'keeps HTML opt-in for existing callers' {
        $export = New-Item -Path "$TestDrive/empty-export" -ItemType Directory
        $reports = New-Item -Path "$TestDrive/json-only" -ItemType Directory
        $output = Join-Path $reports.FullName 'assessment-results.json'
        $report = Export-AzDevOpsAssessmentRun -Result @() -ExportPath $export.FullName -OutputPath $output -Organization fixture -SourceRevision fixture
        Test-Path -LiteralPath $output | Should -BeTrue
        @(Get-ChildItem -LiteralPath $reports.FullName -Filter '*.html').Count | Should -Be 0
        $report.SchemaVersion | Should -Be 1
    }

    It 'requires collection status before writing optional reports' {
        $export = New-Item -Path "$TestDrive/prerequisite-export" -ItemType Directory
        $output = Join-Path $TestDrive 'missing-status.json'
        { Export-AzDevOpsAssessmentRun -Result @() -ExportPath $export.FullName -OutputPath $output -Organization fixture -SourceRevision fixture -HtmlOutputPath "$TestDrive/missing-status.html" } | Should -Throw '*CollectionStatusPath is required*'
        Test-Path -LiteralPath $output | Should -BeFalse
    }
}
AfterAll { Remove-Module DevOpsTools.AzureDevOps.PSRule -Force }
