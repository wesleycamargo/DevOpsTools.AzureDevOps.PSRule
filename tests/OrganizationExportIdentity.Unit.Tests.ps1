BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Organization export identity and diagnostics' -Tag 'Unit' {
    BeforeEach {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $script:connection = [pscustomobject]@{
                Organization = 'test-org'
                OrganizationId = '5e433049-1396-4a9d-80b2-33dc2f1e98af'
            }
            $script:connection | Add-Member -MemberType ScriptMethod -Name GetHeader -Value {
                @{ Authorization = 'Bearer fixture-token' }
            }
            $script:collectionStatus = $null
        }
    }

    AfterEach {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $script:connection = $null
            $script:collectionStatus = $null
        }
    }

    It 'passes the discovered connection ID into the billing collector' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Mock Invoke-AzDevOpsCollectors {
                param ($ExportCommands)
                $billing = @($ExportCommands | Where-Object Name -eq 'Export-AdoOrganizationGeneralBillingSettings')[0]
                $billing.Params.OrganizationId | Should -Be '5e433049-1396-4a9d-80b2-33dc2f1e98af'
            }
            $report = [ordered]@{ Organization = 'test-org'; Projects = @() }
            Invoke-AzDevOpsOrganizationExport -OutputPath $TestDrive -Report $report
            Assert-MockCalled Invoke-AzDevOpsCollectors -Times 1 -Exactly
        }
    }

    It 'uses the connected organization ID when organization export omits it' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            Mock Get-AzDevOpsProject { @() }
            Mock Invoke-AzDevOpsOrganizationExport {
                param ($OrganizationId)
                $OrganizationId | Should -Be '5e433049-1396-4a9d-80b2-33dc2f1e98af'
            }

            Export-AzDevOpsOrganizationRuleData -Organization 'test-org' -OutputPath $TestDrive

            Assert-MockCalled Invoke-AzDevOpsOrganizationExport -Times 1 -Exactly
        }
    }

    It 'fails clearly if the connection does not have a valid organization GUID' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            $script:connection.OrganizationId = ''
            $report = [ordered]@{ Organization = 'test-org'; Projects = @() }
            { Invoke-AzDevOpsOrganizationExport -OutputPath $TestDrive -Report $report } |
                Should -Throw '*OrganizationId must be a valid GUID*'
        }
    }

    It 'includes the underlying error in the collector failure output' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule {
            function Invoke-FixtureFailingCollector {
                [CmdletBinding()]
                param ([string]$OutputPath)
                throw 'fixture collector failure'
            }
            $report = [ordered]@{ Collectors = @() }
            $export = @(@{ Name = 'Invoke-FixtureFailingCollector'; Params = @{} })
            $errors = @()
            Invoke-AzDevOpsCollectors -ExportCommands $export -OutputPath $TestDrive -CollectionReport $report -ErrorVariable +errors 3>$null
            $report.Collectors[0].Status | Should -Be 'Failed'
            ($errors | Out-String) | Should -Match 'fixture collector failure'
            Remove-Item Function:Invoke-FixtureFailingCollector -ErrorAction SilentlyContinue
        }
    }
}

AfterAll {
    Remove-Module DevOpsTools.AzureDevOps.PSRule -Force
}
