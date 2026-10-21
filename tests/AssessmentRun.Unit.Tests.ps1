BeforeAll {
    Import-Module "$PSScriptRoot/../src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psd1" -Force
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
        }
        $sarifPath = "$TestDrive/raw.sarif"
        $rules = 'Azure.DevOps.Repos.Branch.HasBranchPolicy', 'Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled'
        $null = Assert-PSRule -InputPath ($export.FullName + [IO.Path]::DirectorySeparatorChar) -Module PSRule.Rules.AzureDevOps -Name $rules -Outcome All -Culture en -OutputPath $sarifPath -OutputFormat Sarif -ResultVariable raw -ErrorAction SilentlyContinue
        $before = Get-Content $sarifPath -Raw
        $report = Export-AzDevOpsAssessmentRun -Result @($raw) -ExportPath $export.FullName -OutputPath "$TestDrive/assessment.json" -Organization fixture -SourceRevision synthetic-commit
        $report.Projects.Count | Should -Be 2
        $report.Projects[0].ScopeId | Should -Not -Be $report.Projects[1].ScopeId
        foreach ($project in $report.Projects) {
            $project.Findings.Count | Should -Be 2
            $project.RiskObjectives.Count | Should -Be 1
        }
        (Get-Content $sarifPath -Raw) | Should -Be $before
        $sarif = $before | ConvertFrom-Json
        $sarif.runs[0].results.Count | Should -Be 4
        @($sarif.runs[0].results.rule.id | Sort-Object -Unique).Count | Should -Be 2
        $serialized = Get-Content "$TestDrive/assessment.json" -Raw
        $serialized | Should -Not -Match 'private-fixture-payload|syntheticPayloadMustNotBePublished'
        $report.RuleSetVersion | Should -Be '2026.10.21.1'
        $report.SeverityPolicyVersion | Should -Be '1.0.0'
        $report.SourceRevision | Should -Be 'synthetic-commit'
    }
}
AfterAll { Remove-Module PSRule.Rules.AzureDevOps -Force }
