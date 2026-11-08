BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Assessment evidence semantics' -Tag 'Unit' {
    It 'fails a confirmed direct sensitive grant even when collection status is partial' {
        $policy = @{ Reference = 'synthetic-policy-v1'; NamespaceId = 'fixture'; SensitiveMask = 6; Allowed = @{} }
        $evidence = @{
            SchemaVersion = 1; Status = 'Partial'; NamespaceId = 'fixture'; Token = 'project/resource'
            ScopeComplete = $false; IdentitiesComplete = $false; AdministratorsComplete = $false
            Acls = @(@{ token = 'project/resource'; inheritPermissions = $true; acesDictionary = @{ user = @{ descriptor = 'user'; allow = 6; deny = 0 } } })
        }
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Fail'
    }

    It 'does not classify an unconventional resource name as nonproduction' {
        $target = [pscustomobject]@{ ObjectType = 'Azure.DevOps.Pipelines.Environment'; ObjectName = 'fixture.blue'; name = 'blue'; Checks = @() }
        (Test-AzDevOpsProductionTarget -TargetObject $target).Outcome | Should -Be 'Unknown'
    }

    It 'projects unclassified production controls as Unknown rather than NotApplicable' {
        $type = 'Azure.DevOps.Pipelines.Environment'
        $target = [pscustomobject]@{ ObjectType = $type; ObjectName = 'fixture.blue'; name = 'blue'; Checks = @() }
        $raw = [pscustomobject]@{
            RuleName = 'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection'; TargetType = $type
            TargetName = "$type/fixture.blue"; Outcome = 'None'; OutcomeReason = 'Processed'; Reason = @()
        }
        (ConvertTo-AzDevOpsAssessment @($raw) @($target) 'fixture/project').Findings[0].Outcome | Should -Be 'Unknown'
    }

    It 'projects an unclassified classic release stage as Unknown rather than NotApplicable' {
        $type = 'Azure.DevOps.Pipelines.Releases.Definition'
        $target = [pscustomobject]@{ ObjectType = $type; ObjectName = 'fixture.release'; environments = @(@{ name = 'blue' }) }
        $raw = [pscustomobject]@{
            RuleName = 'Azure.DevOps.Pipelines.Releases.Definition.ProductionApproval'; TargetType = $type
            TargetName = "$type/fixture.release"; Outcome = 'None'; OutcomeReason = 'Processed'; Reason = @()
        }
        (ConvertTo-AzDevOpsAssessment @($raw) @($target) 'fixture/project').Findings[0].Outcome | Should -Be 'Unknown'
    }
}

AfterAll { Remove-Module DevOpsTools.AzureDevOps.PSRule -Force }
