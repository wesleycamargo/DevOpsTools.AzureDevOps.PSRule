Describe 'Azure DevOps assessment pipeline authentication' -Tag 'Unit' {
    BeforeAll {
        $script:pipelinePath = Join-Path $PSScriptRoot 'pipelines/azure-pipelines.yml'
    }

    It 'uses the Azure service connection credentials for DevOps authentication' {
        $pipeline = Get-Content -LiteralPath $script:pipelinePath -Raw

        $pipeline | Should -Match '(?m)^\s*addSpnToEnvironment:\s*true\s*$'
        $pipeline | Should -Match 'Connect-AzDevOps\s+`'
        $pipeline | Should -Match '-TenantId\s+\$env:tenantId\s+`'
        $pipeline | Should -Match '-ClientId\s+\$env:servicePrincipalId\s+`'
        $pipeline | Should -Match '-ClientSecret\s+\$env:servicePrincipalKey'
        $pipeline | Should -Not -Match 'az account get-access-token'
    }

    It 'clones the triggering branch when moduleRef is not specified' {
        $pipeline = Get-Content -LiteralPath $script:pipelinePath -Raw

        $pipeline | Should -Match 'default: '''''
        $pipeline | Should -Match 'BUILD_SOURCEBRANCH: \$\(Build.SourceBranch\)'
        $pipeline | Should -Match "\$moduleRef = '\$\{\{ parameters\.moduleRef \}\}'"
        $pipeline | Should -Match '\$moduleRef = \$env:BUILD_SOURCEBRANCH -replace ''\^refs/heads/'''
        $pipeline | Should -Match 'git clone --depth 1 --branch \$moduleRef'
    }

    It 'publishes assessment findings without treating them as collector failures' {
        $pipeline = Get-Content -LiteralPath $script:pipelinePath -Raw

        $pipeline | Should -Not -Match '(?m)^\s*continueOnError:\s*true\s*$'
        $pipeline | Should -Not -Match '-As\s+Detail'
        $pipeline | Should -Match '-Style\s+Plain'
        $pipeline | Should -Match '\$reportPath = Join-Path \$env:BUILD_ARTIFACTSTAGINGDIRECTORY ''psrule-results\.md'''
        $pipeline | Should -Match '-OutputPath \$reportPath\s+`\s*\n\s*-OutputFormat Markdown'
        $pipeline | Should -Match 'if \(\$_.FullyQualifiedErrorId -eq ''PSRule\.Fail,Assert-PSRule''\)'
        $pipeline | Should -Match '(?m)^\s*throw\s*$'
    }

    It 'generates HTML alongside Markdown in the published artifact directory' {
        $pipeline = Get-Content -LiteralPath $script:pipelinePath -Raw

        $pipeline | Should -Match '\$htmlPath = Join-Path \$env:BUILD_ARTIFACTSTAGINGDIRECTORY ''psrule-report\.html'''
        $pipeline | Should -Match '\$assessmentPath = Join-Path \$env:BUILD_ARTIFACTSTAGINGDIRECTORY ''assessment-results\.json'''
        $pipeline | Should -Match '\$assessmentResults = @\(Invoke-PSRule'
        $pipeline | Should -Match 'Export-AzDevOpsAssessmentRun -Result \$assessmentResults -ExportPath \$exportPath'
        $pipeline | Should -Match '-HtmlOutputPath \$htmlPath -CollectionStatusPath \$completenessPath'
        $pipeline | Should -Match '-SourceRevision \$env:BUILD_SOURCEVERSION'
        $pipeline | Should -Match 'PublishPipelineArtifact@1'
        $pipeline | Should -Match 'condition: always\(\)'
        $pipeline | Should -Match 'targetPath: \$\(Build.ArtifactStagingDirectory\)'
    }

    It 'publishes the generated HTML as a report tab' {
        $pipeline = Get-Content -LiteralPath $script:pipelinePath -Raw

        $pipeline | Should -Match 'task: PublishHtmlReport@1'
        $pipeline | Should -Match 'task.setvariable variable=PSRuleHtmlReportReady\]true'
        $pipeline | Should -Match 'task.setvariable variable=PSRuleHtmlReportPath\]\$htmlPath'
        $pipeline | Should -Match 'condition: and\(succeededOrFailed\(\), eq\(variables\[''PSRuleHtmlReportReady''\], ''true''\)\)'
        $pipeline | Should -Match 'reportDir: \$\(PSRuleHtmlReportPath\)'
        $pipeline | Should -Match 'tabName: Project assessment'
    }
}
