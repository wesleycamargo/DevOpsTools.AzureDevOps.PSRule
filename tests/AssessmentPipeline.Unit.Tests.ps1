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

        $pipeline | Should -Match 'BUILD_SOURCEBRANCH: \$\(Build.SourceBranch\)'
        $pipeline | Should -Match '\$moduleRef = if \(\$env:MODULE_REF\)'
        $pipeline | Should -Match 'git clone --depth 1 --branch \$moduleRef'
    }
}
