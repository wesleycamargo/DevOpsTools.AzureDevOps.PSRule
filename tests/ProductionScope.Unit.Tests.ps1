BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Explicit production target classification' -Tag 'Unit' {
    It 'does not mistake <Name> for production' -ForEach @(
        @{ Name = 'main' }
        @{ Name = 'master' }
        @{ Name = 'product' }
        @{ Name = 'delivery' }
        @{ Name = 'liveness' }
    ) {
        foreach ($type in @('Azure.DevOps.Pipelines.Environment', 'Azure.DevOps.ServiceConnection')) {
            $target = [pscustomobject]@{
                ObjectType = $type; ObjectName = "org.project.$Name"; name = $Name; Checks = @()
            }
            $pattern = if ($type -eq 'Azure.DevOps.Pipelines.Environment') {
                'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection'
            } else { 'Azure.DevOps.ServiceConnections.ProductionCheckProtection' }
            @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $pattern -Culture en).Count | Should -Be 0
        }
    }

    It 'uses an exact configured mapping in preference to name matching' {
        $targets = @(
            [pscustomobject]@{ ObjectType = 'Azure.DevOps.Pipelines.Environment'; ObjectName = 'org.project.staging'; name = 'staging'; Checks = @() }
            [pscustomobject]@{ ObjectType = 'Azure.DevOps.Pipelines.Environment'; ObjectName = 'org.project.production'; name = 'production'; Checks = @() }
            [pscustomobject]@{ ObjectType = 'Azure.DevOps.ServiceConnection'; ObjectName = 'org.project.service'; name = 'service'; Checks = @() }
        )
        $option = New-PSRuleOption -Configuration @{
            productionTargets = @{
                'Azure.DevOps.Pipelines.Environment' = @('org.project.staging')
                'Azure.DevOps.ServiceConnection' = @('org.project.service')
            }
        }
        $results = @($targets | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name @(
            'Azure.DevOps.Pipelines.Environments.ProductionCheckProtection',
            'Azure.DevOps.ServiceConnections.ProductionCheckProtection'
        ) -Option $option -Culture en)
        $results.Count | Should -Be 2
        @($results | Where-Object TargetName -Like '*staging').Count | Should -Be 1
        @($results | Where-Object TargetName -Like '*production').Count | Should -Be 0
        @($results | Where-Object TargetName -Like '*service').Count | Should -Be 1
    }

    It 'selects the correct classic release stage using an explicit mapping' {
        $target = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.Pipelines.Releases.Definition'
            ObjectName = 'org.project.release'
            environments = @(
                @{ name = 'production'; preDeployApprovals = @{ approvals = @(@{ approver = @{ displayName = 'synthetic' } }); approvalOptions = @{ releaseCreatorCanBeApprover = $false } } }
                @{ name = 'acceptance'; preDeployApprovals = @{ approvals = @(); approvalOptions = @{ releaseCreatorCanBeApprover = $true } } }
            )
        }
        $option = New-PSRuleOption -Configuration @{
            productionReleaseEnvironments = @{ 'org.project.release' = @('acceptance') }
        }
        $rules = @('Azure.DevOps.Pipelines.Releases.Definition.ProductionApproval',
                   'Azure.DevOps.Pipelines.Releases.Definition.SelfApproval')
        $results = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $rules -Option $option -Culture en)
        $results.Count | Should -Be 2
        @($results | Where-Object Outcome -EQ 'Fail').Count | Should -Be 2
    }
}

Describe 'Production branch restriction evidence' -Tag 'Unit' {
    It 'rejects unrestricted entries mixed with named branches on <Type>' -ForEach @(
        @{ Type = 'Azure.DevOps.Pipelines.Environment'; Prefix = 'Azure.DevOps.Pipelines.Environments' }
        @{ Type = 'Azure.DevOps.ServiceConnection'; Prefix = 'Azure.DevOps.ServiceConnections' }
    ) {
        foreach ($branches in @(
            'refs/heads/main,refs/heads/*',
            'refs/heads/*,refs/heads/main',
            ' refs/heads/main ; refs/heads/* ',
            'refs/heads/main,*',
            'refs/heads/main,refs/heads/**',
            'refs/heads/main,main'
        )) {
            $target = [pscustomobject]@{
                ObjectType = $Type
                ObjectName = 'fixture.production'
                name = 'production'
                Checks = @(@{
                    isDisabled = $false
                    type = @{ name = 'Branch control' }
                    settings = @{ inputs = @{ allowedBranches = $branches } }
                })
            }
            $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule `
                -Name "$Prefix.ProductionBranchLimit" -Culture en -ErrorAction Stop)
            $raw.Count | Should -Be 1
            $raw[0].Outcome | Should -Be 'Fail' -Because "the union '$branches' is not a restricted allowlist"
            (Get-AzDevOpsProductionGateAssessment -TargetObject $target).Outcome | Should -Be 'Fail'
        }
    }

    It 'preserves restricted lists, arrays, disabled gates and independent checks' {
        $check = @{
            isDisabled = $false
            type = @{ name = 'Branch control' }
            settings = @{ inputs = @{ allowedBranches = 'refs/heads/main' } }
        }
        $target = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.Pipelines.Environment'
            ObjectName = 'fixture.production'
            name = 'production'
            Checks = @($check)
        }
        $rule = 'Azure.DevOps.Pipelines.Environments.ProductionBranchLimit'
        foreach ($scenario in @(
            @{ Branches = 'refs/heads/main,refs/heads/release'; Expected = 'Pass' }
            @{ Branches = 'refs/heads/releases/*'; Expected = 'Pass' }
            @{ Branches = @('refs/heads/main', 'refs/heads/release'); Expected = 'Pass' }
            @{ Branches = @('refs/heads/main', 'refs/heads/*'); Expected = 'Fail' }
            @{ Branches = ''; Expected = 'Fail' }
            @{ Branches = '  ; , '; Expected = 'Fail' }
        )) {
            $check.settings.inputs.allowedBranches = $scenario.Branches
            $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule `
                -Name $rule -Culture en -ErrorAction Stop)
            $raw.Count | Should -Be 1
            $raw[0].Outcome | Should -Be $scenario.Expected
        }
        $check.settings.inputs.allowedBranches = 'refs/heads/main'
        $check.isDisabled = $true
        $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $rule -Culture en)
        $raw[0].Outcome | Should -Be 'Fail'

        $check.isDisabled = $false
        $target.Checks += @{
            isDisabled = $false
            type = @{ name = 'Branch control' }
            settings = @{ inputs = @{ allowedBranches = 'refs/heads/*' } }
        }
        $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $rule -Culture en)
        $raw[0].Outcome | Should -Be 'Pass'
    }

    It 'checks the actual active branch-control gate on <Type>' -ForEach @(
        @{ Type = 'Azure.DevOps.Pipelines.Environment'; Rule = 'Azure.DevOps.Pipelines.Environments.ProductionBranchLimit' }
        @{ Type = 'Azure.DevOps.ServiceConnection'; Rule = 'Azure.DevOps.ServiceConnections.ProductionBranchLimit' }
    ) {
        $target = [pscustomobject]@{
            ObjectType = $Type; ObjectName = 'fixture.production'; name = 'production'
            Checks = @(
                @{ isDisabled = $false; type = @{ name = 'Branch control' }; settings = @{ inputs = @{ allowedBranches = 'refs/heads/main' } } }
            )
        }
        foreach ($scenario in @(
            @{ Branches = 'refs/heads/main'; Disabled = $false; Expected = 'Pass' }
            @{ Branches = '*'; Disabled = $false; Expected = 'Fail' }
            @{ Branches = 'refs/heads/*'; Disabled = $false; Expected = 'Fail' }
            @{ Branches = 'refs/heads/main'; Disabled = $true; Expected = 'Fail' }
        )) {
            $target.Checks[0].settings.inputs.allowedBranches = $scenario.Branches
            $target.Checks[0].isDisabled = $scenario.Disabled
            $result = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $Rule -Culture en)
            $result.Count | Should -Be 1
            $result[0].Outcome | Should -Be $scenario.Expected
        }

        # A configured branch control with unavailable settings must not become a pass or N/A.
        $target.Checks[0].isDisabled = $false
        $target.Checks[0].settings.inputs.Remove('allowedBranches')
        $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $Rule -Outcome All -Culture en)
        $report = ConvertTo-AzDevOpsAssessment $raw @($target) 'fixture/project'
        @($report.Findings | Where-Object { $_.RuleId -eq $Rule -and $_.Outcome -eq 'Unknown' }).Count | Should -Be 1
    }

    It 'rejects a branch policy that is not a branch-control check' {
        $target = [pscustomobject]@{
            ObjectType = 'Azure.DevOps.ServiceConnection'; ObjectName = 'fixture.production'; name = 'production'
            Checks = @(@{ type = @{ name = 'Approval' }; settings = @{ approvers = @(@{ id = 'synthetic' }); inputs = @{ allowedBranches = 'refs/heads/main' } } })
        }
        $rule = 'Azure.DevOps.ServiceConnections.ProductionBranchLimit'
        $raw = @($target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $rule -Culture en)
        $raw[0].Outcome | Should -Be 'Fail'
    }
}

AfterAll {
    Remove-Module DevOpsTools.AzureDevOps.PSRule -Force
}
