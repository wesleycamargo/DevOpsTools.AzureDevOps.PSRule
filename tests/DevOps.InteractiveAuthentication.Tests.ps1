BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Connect-AzDevOps interactive authentication' -Tag 'Unit' {
    BeforeEach {
        Disconnect-AzDevOps
        Mock Invoke-RestMethod -ModuleName DevOpsTools.AzureDevOps.PSRule {
            [pscustomobject]@{ value = @() }
        }
        Mock Invoke-RestMethod -ModuleName DevOpsTools.AzureDevOps.PSRule {
            [pscustomobject]@{ instanceId = '5e433049-1396-4a9d-80b2-33dc2f1e98af' }
        } -ParameterFilter { $Uri -like '*_apis/connectionData*' }
    }

    Context 'Azure CLI' {
        BeforeEach {
            $script:testAzureCliSignedIn = $true
            $script:testAzureCliToken = 'session.token.signature'
            Mock Invoke-AzDevOpsInteractiveAzureCli -ModuleName DevOpsTools.AzureDevOps.PSRule {
                if ($ShowLoginOutput) {
                    $script:testAzureCliSignedIn = $true
                    return @{ ExitCode = 0 }
                }
                if (-not $script:testAzureCliSignedIn) {
                    return @{ ExitCode = 1; Diagnostic = "ERROR: Please run 'az login' to setup account." }
                }
                return @{
                    ExitCode = 0
                    Output = @{
                        accessToken = $script:testAzureCliToken
                        expires_on = [DateTimeOffset]::UtcNow.AddMinutes(30).ToUnixTimeSeconds()
                        tenant = 'b68f483a-cf22-4691-ade9-09ba4a7ad96c'
                    } | ConvertTo-Json -Compress
                }
            }
        }

        It 'uses the existing Azure CLI session and discovers the organization ID' {
            Connect-AzDevOps -Organization test-org -Interactive -TokenType ReadOnly

            InModuleScope DevOpsTools.AzureDevOps.PSRule {
                $script:connection.AuthType | Should -Be Interactive
                $script:connection.TokenType | Should -Be ReadOnly
                $script:connection.OrganizationId | Should -Be '5e433049-1396-4a9d-80b2-33dc2f1e98af'
                $script:connection.TokenExpires.Kind | Should -Be Utc
                $script:connection.GetHeader().Authorization | Should -Be 'Bearer session.token.signature'
            }
            Should -Invoke Invoke-AzDevOpsInteractiveAzureCli -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 1 -Exactly -ParameterFilter {
                $Arguments -contains 'get-access-token' -and $Arguments -contains '499b84ac-1321-427f-aa17-267ca6975798'
            }
            Should -Invoke Invoke-AzDevOpsInteractiveAzureCli -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 0 -Exactly -ParameterFilter { $ShowLoginOutput }
        }

        It 'signs in once when needed and retries token acquisition with the requested tenant' {
            $script:testAzureCliSignedIn = $false
            Connect-AzDevOps -Organization test-org -Interactive -TenantId b68f483a-cf22-4691-ade9-09ba4a7ad96c

            Should -Invoke Invoke-AzDevOpsInteractiveAzureCli -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 1 -Exactly -ParameterFilter {
                $ShowLoginOutput -and $Arguments -contains '--allow-no-subscriptions' -and $Arguments -contains 'b68f483a-cf22-4691-ade9-09ba4a7ad96c'
            }
            Should -Invoke Invoke-AzDevOpsInteractiveAzureCli -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 2 -Exactly -ParameterFilter {
                $Arguments -contains 'get-access-token' -and $Arguments -contains 'b68f483a-cf22-4691-ade9-09ba4a7ad96c'
            }
        }

        It 'returns a cancellation error without verifying an organization' {
            $script:testAzureCliSignedIn = $false
            Mock Invoke-AzDevOpsInteractiveAzureCli -ModuleName DevOpsTools.AzureDevOps.PSRule {
                @{ ExitCode = 1; Diagnostic = 'ERROR: User cancelled the Accounts Control Operation' }
            } -ParameterFilter { $ShowLoginOutput }

            { Connect-AzDevOps -Organization test-org -Interactive } | Should -Throw 'Azure CLI sign-in was canceled.'
            Should -Invoke Invoke-RestMethod -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 0 -Exactly
        }

        It 'reports an access denial without opening sign-in again' {
            Mock Invoke-RestMethod -ModuleName DevOpsTools.AzureDevOps.PSRule {
                $exception = [System.Exception]::new('Sensitive diagnostic')
                $exception | Add-Member -NotePropertyName Response -NotePropertyValue @{ StatusCode = 403 }
                throw $exception
            } -ParameterFilter { $Uri -like '*_apis/projects*' }

            { Connect-AzDevOps -Organization test-org -Interactive } | Should -Throw '*Azure DevOps denied access*'
            Should -Invoke Invoke-AzDevOpsInteractiveAzureCli -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 0 -Exactly -ParameterFilter { $ShowLoginOutput }
        }

        It 'renews an expired token through the same provider and tenant' {
            Connect-AzDevOps -Organization test-org -Interactive
            $script:testAzureCliToken = 'renewed.token.signature'
            InModuleScope DevOpsTools.AzureDevOps.PSRule {
                $script:connection.TokenExpires = [datetime]::MinValue
                $script:connection.GetHeader().Authorization | Should -Be 'Bearer renewed.token.signature'
            }
            Should -Invoke Invoke-AzDevOpsInteractiveAzureCli -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 1 -Exactly -ParameterFilter {
                $Arguments -contains 'get-access-token' -and $Arguments -contains 'b68f483a-cf22-4691-ade9-09ba4a7ad96c'
            }
            Should -Invoke Invoke-AzDevOpsInteractiveAzureCli -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 0 -Exactly -ParameterFilter { $ShowLoginOutput }
        }

        It 'asks the caller to reconnect if renewal requires authentication' {
            Connect-AzDevOps -Organization test-org -Interactive
            $script:testAzureCliSignedIn = $false
            InModuleScope DevOpsTools.AzureDevOps.PSRule {
                $script:connection.TokenExpires = [datetime]::MinValue
                { $script:connection.GetHeader() } | Should -Throw '*Run Connect-AzDevOps -Interactive again*'
            }
            Should -Invoke Invoke-AzDevOpsInteractiveAzureCli -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 0 -Exactly -ParameterFilter { $ShowLoginOutput }
        }

        It 'includes reconnection guidance in the assessment failure' {
            Connect-AzDevOps -Organization test-org -Interactive
            $script:testAzureCliSignedIn = $false
            InModuleScope DevOpsTools.AzureDevOps.PSRule {
                $script:connection.TokenExpires = [datetime]::MinValue
            }

            { Export-AzDevOpsRuleData -Project test-project -PassThru -Strict 2>$null 3>$null } |
                Should -Throw '*Run Connect-AzDevOps -Interactive again*'
            Should -Invoke Invoke-AzDevOpsInteractiveAzureCli -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 0 -Exactly -ParameterFilter { $ShowLoginOutput }
        }
    }

    Context 'Azure PowerShell' {
        BeforeAll {
            # Stub optional module commands so these tests run without Az.Accounts installed.
            $azAccountsStub = New-Module -Name Az.Accounts -ScriptBlock {
                function Get-AzAccessToken {
                    [CmdletBinding()]
                    param ([string]$ResourceUrl, [string]$TenantId)
                    throw 'Expected a Pester mock.'
                }
                function Connect-AzAccount {
                    [CmdletBinding()]
                    param ([string]$Tenant, [switch]$SkipContextPopulation, [string]$Scope)
                    throw 'Expected a Pester mock.'
                }
            }
            Import-Module $azAccountsStub -Global
        }

        BeforeEach {
            $script:testAzurePowerShellSignedIn = $true
            Mock Get-AzAccessToken -ModuleName DevOpsTools.AzureDevOps.PSRule {
                if (-not $script:testAzurePowerShellSignedIn) { throw 'Please run Connect-AzAccount to login.' }
                [pscustomobject]@{
                    Token = ConvertTo-SecureString 'az.accounts.token' -AsPlainText -Force
                    ExpiresOn = [DateTimeOffset]::UtcNow.AddMinutes(15)
                    TenantId = 'b68f483a-cf22-4691-ade9-09ba4a7ad96c'
                }
            }
            Mock Connect-AzAccount -ModuleName DevOpsTools.AzureDevOps.PSRule { $script:testAzurePowerShellSignedIn = $true }
        }

        It 'uses the existing Az.Accounts context and handles its SecureString token' {
            Connect-AzDevOps -Organization test-org -Interactive -AuthProvider AzurePowerShell
            InModuleScope DevOpsTools.AzureDevOps.PSRule {
                $script:connection.GetHeader().Authorization | Should -Be 'Bearer az.accounts.token'
            }
            Should -Invoke Get-AzAccessToken -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 1 -Exactly -ParameterFilter {
                $ResourceUrl -eq '499b84ac-1321-427f-aa17-267ca6975798'
            }
            Should -Invoke Connect-AzAccount -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 0 -Exactly
        }

        It 'opens Az.Accounts sign-in when its existing context cannot get a token' {
            $script:testAzurePowerShellSignedIn = $false
            Connect-AzDevOps -Organization test-org -Interactive -AuthProvider AzurePowerShell -TenantId b68f483a-cf22-4691-ade9-09ba4a7ad96c

            Should -Invoke Connect-AzAccount -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 1 -Exactly -ParameterFilter {
                $Scope -eq 'Process' -and $SkipContextPopulation -and $Tenant -eq 'b68f483a-cf22-4691-ade9-09ba4a7ad96c'
            }
            Should -Invoke Get-AzAccessToken -ModuleName DevOpsTools.AzureDevOps.PSRule -Times 2 -Exactly -ParameterFilter {
                $TenantId -eq 'b68f483a-cf22-4691-ade9-09ba4a7ad96c'
            }
        }

        AfterAll { Remove-Module -ModuleInfo $azAccountsStub -ErrorAction SilentlyContinue }
    }

    AfterAll { Remove-Module DevOpsTools.AzureDevOps.PSRule -Force }
}
