BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.Assessment/DevOpsTools.AzureDevOps.Assessment.psd1" -Force
}

Describe 'Variable group secret evidence' -Tag 'Unit' {
    It 'classifies <Name> as <Expected>' -ForEach @(
        @{ Name = 'masked Vsts secret'; Variables = @{ credential = @{ isSecret = $true; value = $null } }; Expected = 'Pass' }
        @{ Name = 'ordinary setting'; Variables = @{ setting = @{ value = 'blue' } }; Expected = 'Pass' }
        @{ Name = 'empty collected group'; Variables = @{}; Expected = 'Pass' }
        @{ Name = 'unmasked declared secret'; Variables = @{ credential = @{ isSecret = $true; value = 'synthetic-only' } }; Expected = 'Fail' }
        @{ Name = 'plaintext connection credential'; Variables = @{ setting = @{ value = 'Password=synthetic;' } }; Expected = 'Fail' }
        @{ Name = 'secret with omitted value'; Variables = @{ credential = @{ isSecret = $true } }; Expected = 'Unknown' }
        @{ Name = 'malformed collection'; Variables = @('synthetic'); Expected = 'Unknown' }
        @{ Name = 'missing collection'; Variables = $null; Expected = 'Unknown' }
        @{ Name = 'missing variable evidence'; Variables = @{ setting = @{} }; Expected = 'Unknown' }
    ) {
        $target = [pscustomobject]@{ type = 'Vsts'; variables = $Variables }
        (Get-AzDevOpsVariableGroupSecretAssessment -TargetObject $target).Outcome | Should -Be $Expected
    }

    It 'preserves both rule identities and accepts encrypted secrets' {
        $target = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.Tasks.VariableGroup'
            ObjectName = 'fixture.masked'
            type = 'Vsts'
            variables = [pscustomobject]@{ credential = [pscustomobject]@{ isSecret = $true; value = $null } }
        }
        $rules = 'Azure.DevOps.Tasks.VariableGroup.NoKeyVaultNoSecrets', 'Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets'
        $results = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name $rules -Outcome All -Culture en -ErrorAction Stop)
        $results.Count | Should -Be 2
        @($results | Where-Object Outcome -NE 'Pass').Count | Should -Be 0
    }

    It 'does not turn unavailable collection into a pass or a security failure' {
        $target = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.Tasks.VariableGroup'
            ObjectName = 'fixture.unavailable'
        }
        $results = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name 'Azure.DevOps.Tasks.VariableGroup.No*Secrets' -Outcome All -Culture en -ErrorAction Stop)
        $results.Count | Should -Be 2
        @($results | Where-Object Outcome -NE 'None').Count | Should -Be 0
        (Get-AzDevOpsVariableGroupSecretAssessment -TargetObject $target).ReasonCode | Should -Be 'VariablesUnavailable'
    }

    It 'detects exposed credentials through both retained diagnostics' {
        $target = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.Tasks.VariableGroup'
            ObjectName = 'fixture.exposed'
            type = 'Vsts'
            variables = [pscustomobject]@{ credential = [pscustomobject]@{ value = 'Password=synthetic;' } }
        }
        $results = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.Assessment -Name 'Azure.DevOps.Tasks.VariableGroup.No*Secrets' -Outcome All -Culture en -ErrorAction Stop)
        $results.Count | Should -Be 2
        @($results | Where-Object Outcome -NE 'Fail').Count | Should -Be 0
    }
}

AfterAll {
    Remove-Module DevOpsTools.AzureDevOps.Assessment -Force
}
