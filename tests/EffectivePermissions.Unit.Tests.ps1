BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}
Describe 'Direct permission evidence' -Tag 'Unit' {
    BeforeEach {
        $policy = @{ Reference = 'synthetic-policy-v1'; NamespaceId = 'fixture'; SensitiveMask = 6; Allowed = @{} }
        $evidence = @{
            SchemaVersion = 1; Status = 'Complete'; NamespaceId = 'fixture'; Token = 'project/resource'; ScopeComplete = $true
            Acls = @(@{ token = 'project/resource'; inheritPermissions = $true; acesDictionary = @{ user = @{ descriptor = 'user'; allow = 1; deny = 0 } } })
        }
    }
    It 'passes complete direct evidence without unauthorized grants' {
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Pass'
    }
    It 'fails a confirmed unauthorized sensitive direct grant' {
        $evidence.Acls[0].acesDictionary.user.allow = 7
        $result = Get-AzDevOpsEffectivePermissionAssessment $evidence $policy
        $result.Outcome | Should -Be 'Fail'
        $result.ReasonCode | Should -Be 'UnauthorizedDirectPermission'
        $result.Violations[0].Mask | Should -Be 6
    }
    It 'preserves approved namespace-specific exception masks' {
        $evidence.Acls[0].acesDictionary.user.allow = 7
        $policy.Allowed.user = 6
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Pass'
        $policy.Allowed.user = 2
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Violations[0].Mask | Should -Be 4
    }
    It 'does not treat inherited grants as direct grants' {
        $evidence.Acls = @(
            @{ token = 'project'; inheritPermissions = $false; acesDictionary = @{ user = @{ descriptor = 'user'; allow = 7; deny = 0 } } }
            @{ token = 'project/resource'; inheritPermissions = $true; acesDictionary = @{} }
        )
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Pass'
    }
    It 'passes an empty ACL only with complete exact-scope evidence' {
        $evidence.Acls[0].acesDictionary = @{}
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Pass'
        $evidence.ScopeComplete = $false
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Unknown'
    }
    It 'returns Unknown for partial or failed evidence without a confirmed violation' -ForEach @('Partial', 'Failed') {
        param($Status)
        $evidence.Status = $Status
        $evidence.ScopeComplete = $false
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Unknown'
    }
    It 'retains a confirmed direct violation when unrelated collection evidence is incomplete' {
        $evidence.Status = 'Partial'; $evidence.ScopeComplete = $false; $evidence.Acls[0].acesDictionary.user.allow = 7
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Fail'
    }
    It 'returns Unknown for wrong namespace, token, malformed ACL, or missing policy' {
        $policy.NamespaceId = 'different'
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Unknown'
        $policy.NamespaceId = 'fixture'; $evidence.Token = 'another/resource'
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Unknown'
        $evidence.Token = 'project/resource'; $evidence.Acls[0].acesDictionary.user.allow = $null
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Unknown'
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $null).ReasonCode | Should -Be 'PermissionPolicyUnavailable'
    }
    It 'evaluates all six retained rule IDs from complete direct evidence' {
        $rules = @(Get-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name '*.InheritedPermissions')
        $rules.Count | Should -Be 6
        $inventory = Get-Content "$PSScriptRoot/../docs/assessment/source-inventory.json" -Raw | ConvertFrom-Json
        $policies = @{}
        $targets = foreach ($rule in $inventory.rules | Where-Object ruleId -Like '*.InheritedPermissions') {
            $policies[$rule.targetType] = $policy
            [pscustomobject]@{ ObjectType = $rule.targetType; ObjectName = $rule.ruleId; PermissionEvidence = $evidence }
        }
        $option = New-PSRuleOption -Configuration @{ effectivePermissionPolicies = $policies }
        $results = @($targets | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name '*.InheritedPermissions' -Option $option -Culture en -ErrorAction Stop)
        $results.Count | Should -Be 6
        @($results | Where-Object Outcome -NE 'Pass').Count | Should -Be 0
    }
}
AfterAll { Remove-Module DevOpsTools.AzureDevOps.PSRule -Force }
