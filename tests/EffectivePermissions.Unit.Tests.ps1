BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}
Describe 'Effective permission evidence' -Tag 'Unit' {
    BeforeEach {
        $policy = @{ Reference = 'synthetic-policy-v1'; NamespaceId = 'fixture'; SensitiveMask = 6; Allowed = @{} }
        $evidence = @{
            SchemaVersion = 1; Status = 'Complete'; NamespaceId = 'fixture'; Token = 'project/resource'
            ScopeComplete = $true; IdentitiesComplete = $true; AdministratorsComplete = $true
            Identities = @(
                @{ descriptor = 'user'; isContainer = $false; bypassMask = 0 }
                @{ descriptor = 'group'; isContainer = $true; members = @('nested'); bypassMask = 0 }
                @{ descriptor = 'nested'; isContainer = $true; members = @('user'); bypassMask = 0 }
            )
            Acls = @(
                @{ token = 'project'; inheritPermissions = $false; acesDictionary = @{ group = @{ descriptor = 'group'; allow = 1; deny = 0 } } }
                @{ token = 'project/resource'; inheritPermissions = $true; acesDictionary = @{} }
            )
        }
    }
    It 'accepts inherited read access' {
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Pass'
    }
    It 'rejects sensitive access inherited through nested groups' {
        $evidence.Acls[0].acesDictionary.group.allow = 7
        $result = Get-AzDevOpsEffectivePermissionAssessment $evidence $policy
        $result.Outcome | Should -Be 'Fail'
        $result.Violations[0].Mask | Should -Be 6
    }
    It 'honors an explicit deny through a second group' {
        $evidence.Acls[0].acesDictionary.group.allow = 7
        $evidence.Acls[1].acesDictionary.nested = @{ descriptor = 'nested'; allow = 0; deny = 6 }
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Pass'
    }
    It 'honors child explicit allow over inherited deny for the same identity' {
        $evidence.Acls[0].acesDictionary.group = @{ descriptor = 'group'; allow = 0; deny = 6 }
        $evidence.Acls[1].acesDictionary.group = @{ descriptor = 'group'; allow = 6; deny = 0 }
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Fail'
    }
    It 'stops inheritance when the target ACL disables it' {
        $evidence.Acls[0].acesDictionary.group.allow = 7
        $evidence.Acls[1].inheritPermissions = $false
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Pass'
    }
    It 'accepts only privileges authorized by policy' {
        $evidence.Acls[0].acesDictionary.group.allow = 7
        $policy.Allowed.group = 6
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Pass'
        $policy.Allowed.group = 2
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Violations[0].Mask | Should -Be 4
    }
    It 'evaluates administrative bypass despite deny entries' {
        $evidence.Identities[0].bypassMask = 6
        $evidence.Acls[0].acesDictionary.group.deny = 6
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Fail'
        $policy.Allowed.user = 6
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Pass'
    }
    It 'handles membership cycles without discarding permissions' {
        $evidence.Identities[2].members += 'group'
        $evidence.Acls[0].acesDictionary.group.allow = 7
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Fail'
    }
    It 'does not pass incomplete <Field> collection' -ForEach @(
        @{ Field = 'ScopeComplete' }; @{ Field = 'IdentitiesComplete' }; @{ Field = 'AdministratorsComplete' }
    ) {
        $evidence[$Field] = $false
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Unknown'
    }
    It 'does not pass unresolved group members' {
        $evidence.Identities[2].members += 'unresolved'
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Unknown'
    }
    It 'does not reuse evidence for a different namespace or token' {
        $policy.NamespaceId = 'different'
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Unknown'
        $policy.NamespaceId = 'fixture'
        $evidence.Token = 'another/resource'
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $policy).Outcome | Should -Be 'Unknown'
    }
    It 'requires an explicit permission policy' {
        (Get-AzDevOpsEffectivePermissionAssessment $evidence $null).ReasonCode | Should -Be 'PermissionPolicyUnavailable'
    }
    It 'evaluates all six legacy IDs using effective permissions' {
        # Derive target types from the actual rules to keep the assertion about retained IDs precise.
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
