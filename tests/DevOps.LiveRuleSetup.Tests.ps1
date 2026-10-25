BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.Assessment/DevOpsTools.AzureDevOps.Assessment.psd1" -Force
    . "$PSScriptRoot/helpers/LiveRuleTestData.ps1"
}

Describe 'Independent live rule test setup' -Tag 'Unit' {
    BeforeEach {
        $savedEnvironment = @{}
        foreach ($name in 'ADO_ORGANIZATION', 'ADO_PROJECT', 'ADO_PAT', 'ADO_PAT_READONLY', 'ADO_PAT_FINEGRAINED') {
            $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
            [Environment]::SetEnvironmentVariable($name, "fixture-$name")
        }
        Mock Connect-AzDevOps {}
        Mock Disconnect-AzDevOps {}
        Mock Export-AzDevOpsGroups {
            param ($OutputPath)
            @{ ObjectType = 'Azure.DevOps.Group'; ObjectName = 'fixture-group' } |
                ConvertTo-Json | Set-Content (Join-Path $OutputPath 'fixture.grp.ado.json')
        }
        $outputPath = Join-Path $TestDrive ([guid]::NewGuid().ToString())
    }

    AfterEach {
        foreach ($name in $savedEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name])
        }
    }

    It 'prepares all permission profiles without exports from another test file' {
        $paths = New-LiveRuleTestData -ExportCommand Export-AzDevOpsGroups -OutputPath $outputPath

        foreach ($profile in 'FullAccess', 'ReadOnly', 'FineGrained') {
            $fixture = Get-Content (Join-Path $paths[$profile] 'fixture.grp.ado.json') -Raw | ConvertFrom-Json
            $fixture.ObjectType | Should -Be 'Azure.DevOps.Group'
            $paths[$profile] | Should -Be (Join-Path $outputPath $profile)
        }
        Should -Invoke Connect-AzDevOps -Times 1 -Exactly -ParameterFilter { $TokenType -eq 'FullAccess' -and $PAT -eq 'fixture-ADO_PAT' }
        Should -Invoke Connect-AzDevOps -Times 1 -Exactly -ParameterFilter { $TokenType -eq 'ReadOnly' -and $PAT -eq 'fixture-ADO_PAT_READONLY' }
        Should -Invoke Connect-AzDevOps -Times 1 -Exactly -ParameterFilter { $TokenType -eq 'FineGrained' -and $PAT -eq 'fixture-ADO_PAT_FINEGRAINED' }
        Should -Invoke Export-AzDevOpsGroups -Times 3 -Exactly -ParameterFilter { $Project -eq 'fixture-ADO_PROJECT' }
        Should -Invoke Disconnect-AzDevOps -Times 3 -Exactly
    }

    It 'reports missing live prerequisites before making any API call' {
        $env:ADO_PAT_READONLY = $null

        { New-LiveRuleTestData -ExportCommand Export-AzDevOpsGroups -OutputPath $outputPath } |
            Should -Throw '*Live rule tests require ADO_PAT_READONLY*'

        Should -Invoke Connect-AzDevOps -Times 0 -Exactly
        Should -Invoke Export-AzDevOpsGroups -Times 0 -Exactly
    }

    It 'closes the connection when collection fails' {
        Mock Export-AzDevOpsGroups { throw 'fixture collection failure' }

        { New-LiveRuleTestData -ExportCommand Export-AzDevOpsGroups -OutputPath $outputPath } |
            Should -Throw 'fixture collection failure'

        Should -Invoke Disconnect-AzDevOps -Times 1 -Exactly
    }

    It 'collects organization settings with the correct organization and PAT header' {
        Mock Export-AdoOrganizationPipelinesSettings {
            param ($OutputPath)
            @{ ObjectType = 'Azure.DevOps.Organization.Pipelines.Settings' } |
                ConvertTo-Json | Set-Content (Join-Path $OutputPath 'OrganizationpipelineSettings.ado.json')
        }

        $paths = New-LiveRuleTestData -ExportCommand Export-AdoOrganizationPipelinesSettings -OutputPath $outputPath

        $header = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(':fixture-ADO_PAT'))
        Should -Invoke Export-AdoOrganizationPipelinesSettings -Times 1 -Exactly -ParameterFilter {
            $Organization -eq 'fixture-ADO_ORGANIZATION' -and $AccessToken -eq $header
        }
        Test-Path (Join-Path $paths.FullAccess 'OrganizationpipelineSettings.ado.json') | Should -BeTrue
        Should -Invoke Export-AzDevOpsGroups -Times 0 -Exactly
    }
}
