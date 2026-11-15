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
        $pipeline | Should -Match 'MODULE_REF: \$\{\{ parameters\.moduleRef \}\}'
        $pipeline | Should -Match '\$moduleRef = if \(\$env:MODULE_REF\)'
        $pipeline | Should -Match 'git clone --depth 1 --branch \$moduleRef'
    }

    It 'publishes assessment findings without treating them as collector failures' {
        $pipeline = Get-Content -LiteralPath $script:pipelinePath -Raw

        $pipeline | Should -Not -Match '(?m)^\s*continueOnError:\s*true\s*$'
        $pipeline | Should -Not -Match '-As\s+Detail'
        $pipeline | Should -Match '-Style\s+Plain'
        $pipeline | Should -Match '\$reportPath = Join-Path \$env:BUILD_ARTIFACTSTAGINGDIRECTORY ''psrule-results\.sarif'''
        $pipeline | Should -Match '-OutputPath \$reportPath\s+`\s*\n\s*-OutputFormat Sarif'
        $pipeline | Should -Match 'if \(\$_.FullyQualifiedErrorId -eq ''PSRule\.Fail,Assert-PSRule''\)'
        $pipeline | Should -Match '(?m)^\s*throw\s*$'
    }

    It 'generates JSON alongside SARIF in the published artifact directory' {
        $pipeline = Get-Content -LiteralPath $script:pipelinePath -Raw

        $pipeline | Should -Match '\$assessmentPath = Join-Path \$env:BUILD_ARTIFACTSTAGINGDIRECTORY ''assessment-results\.json'''
        $pipeline | Should -Match '\$assessmentResults = @\(Invoke-PSRule'
        $pipeline | Should -Match 'Export-AzDevOpsAssessmentRun -Result \$assessmentResults -ExportPath \$exportPath'
        $pipeline | Should -Match '-SourceRevision \$env:BUILD_SOURCEVERSION'
        $pipeline | Should -Match 'PublishPipelineArtifact@1'
        $pipeline | Should -Match 'condition: always\(\)'
        $pipeline | Should -Match 'targetPath: \$\(Build.ArtifactStagingDirectory\)'
    }
}
