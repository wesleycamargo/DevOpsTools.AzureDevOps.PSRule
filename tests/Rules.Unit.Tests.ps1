BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Rules with synthetic fixtures' -Tag 'Unit' {
    Context 'Project visibility' {
        It 'passes for a private project in every permission-profile fixture' {
            foreach ($profile in 'FullAccess', 'ReadOnly', 'FineGrained') {
                $fixture = [pscustomobject]@{
                    ObjectType = 'Azure.DevOps.Project'
                    ObjectName = "fixture.$profile.private-project"
                    visibility = 'private'
                }

                $fixturePath = Join-Path $TestDrive $profile
                New-Item -Path $fixturePath -ItemType Directory | Out-Null
                $fixture | ConvertTo-Json | Set-Content (Join-Path $fixturePath 'private-project.prj.ado.json')
                $inputObject = Get-Content (Join-Path $fixturePath 'private-project.prj.ado.json') -Raw | ConvertFrom-Json
                $result = @($inputObject | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name Azure.DevOps.Project.Visibility -Culture en)
                $result.Count | Should -Be 1
                $result[0].Outcome | Should -Be 'Pass'
            }
        }

        It 'fails for a public project' {
            $fixture = [pscustomobject]@{
                ObjectType = 'Azure.DevOps.Project'
                ObjectName = 'fixture.full-access.public-project'
                visibility = 'public'
            }

            $result = @($fixture | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name Azure.DevOps.Project.Visibility -Culture en)
            $result.Count | Should -Be 1
            $result[0].Outcome | Should -Be 'Fail'
        }
    }

    Context 'Variable group controls' {
        It 'passes description and no-key-vault-secret checks for a documented group without secrets' {
            $fixture = [pscustomobject]@{
                ObjectType = 'Azure.DevOps.Tasks.VariableGroup'
                ObjectName = 'fixture.safe-variable-group'
                type = 'Vsts'
                description = 'Synthetic offline test fixture.'
                variables = [pscustomobject]@{
                    setting = [pscustomobject]@{ value = 'safe-value' }
                }
            }

            $result = @($fixture | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name @(
                'Azure.DevOps.Tasks.VariableGroup.Description',
                'Azure.DevOps.Tasks.VariableGroup.NoKeyVaultNoSecrets'
            ) -Culture en)
            $result.Count | Should -Be 2
            $result.Outcome | Should -Not -Contain 'Fail'
        }

        It 'accepts a masked Vsts secret without requiring Key Vault' {
            $fixture = [pscustomobject]@{
                ObjectType = 'Azure.DevOps.Tasks.VariableGroup'
                ObjectName = 'fixture.secret-variable-group'
                type = 'Vsts'
                description = 'Synthetic offline test fixture.'
                variables = [pscustomobject]@{
                    secret = [pscustomobject]@{ value = $null; isSecret = $true }
                }
            }

            $result = @($fixture | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name Azure.DevOps.Tasks.VariableGroup.NoKeyVaultNoSecrets -Culture en)
            $result.Count | Should -Be 1
            $result[0].Outcome | Should -Be 'Pass'
        }
    }
}

AfterAll {
    Remove-Module DevOpsTools.AzureDevOps.PSRule -Force
}
