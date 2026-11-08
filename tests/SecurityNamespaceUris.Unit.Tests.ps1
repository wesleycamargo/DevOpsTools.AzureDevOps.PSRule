BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Security namespace URI construction' -Tag Unit {
    BeforeEach {
        $global:capturedAclUris = @()
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod {
            if ($Uri -like '*/_apis/connectionData*') {
                return [pscustomobject]@{ instanceId = '00000000-0000-0000-0000-000000000099' }
            }
            if ($Uri -like '*/_apis/accesscontrollists/*') {
                $global:capturedAclUris += $Uri
            }
            [pscustomobject]@{ value = @() }
        }
        Connect-AzDevOps -Organization fixture-org -PAT fixture-token
    }

    AfterEach {
        Disconnect-AzDevOps
        Remove-Variable -Name capturedAclUris -Scope Global -ErrorAction SilentlyContinue
    }

    It 'uses each security namespace ID in project ACL requests' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Get-AzDevOpsProjectAcls -ProjectId '00000000-0000-0000-0000-000000000001' | Out-Null
        }

        $projectId = '00000000-0000-0000-0000-000000000001'
        $expectedUris = @(
            "https://dev.azure.com/fixture-org/_apis/accesscontrollists/83d4c2e6-e57d-4d6e-892b-b87222b7ad20?includeExtendedInfo=true&api-version=7.2-preview.1&token=Environments/$projectId"
            "https://dev.azure.com/fixture-org/_apis/accesscontrollists/33344d9c-fc72-4d6f-aba5-fa317101a7e9?includeExtendedInfo=true&api-version=7.2-preview.1&token=$projectId"
            "https://dev.azure.com/fixture-org/_apis/accesscontrollists/c788c23e-1b46-4162-8f5e-d7585343b5de?includeExtendedInfo=true&api-version=7.2-preview.1&token=$projectId"
            "https://dev.azure.com/fixture-org/_apis/accesscontrollists/2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87?includeExtendedInfo=true&api-version=7.2-preview.1&token=repoV2/$projectId"
            "https://dev.azure.com/fixture-org/_apis/accesscontrollists/49b48001-ca20-4adc-8111-5b60c903a50c?includeExtendedInfo=true&api-version=7.2-preview.1&token=endpoints/$projectId"
            "https://dev.azure.com/fixture-org/_apis/accesscontrollists/b7e84409-6553-448a-bbb2-af228e07cbeb?includeExtendedInfo=true&api-version=7.2-preview.1&token=Library/$projectId"
        )

        $global:capturedAclUris.Count | Should -Be 6
        foreach ($expectedUri in $expectedUris) {
            $global:capturedAclUris | Should -Contain $expectedUri
        }
    }

    It 'delimits scoped namespace variables before ACL query strings' {
        $functionsPath = Join-Path $PSScriptRoot '../src/DevOpsTools.AzureDevOps.PSRule/Functions'
        $unscopedNamespaceUris = Get-ChildItem -LiteralPath $functionsPath -Filter '*.ps1' -File |
            Select-String -Pattern '\$script:AzureDevOps\w+SecurityNamespaceId\?'

        $unscopedNamespaceUris | Should -BeNullOrEmpty
    }
}
