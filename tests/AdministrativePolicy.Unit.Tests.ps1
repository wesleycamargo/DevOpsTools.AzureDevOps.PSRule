BeforeAll {
    Import-Module "$PSScriptRoot/../src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psd1" -Force
}
Describe 'Approved administrative operating models' -Tag 'Unit' {
    It 'accepts five justified administrators and a one-admin recovery model under explicit thresholds' {
        $targets = @(
            [pscustomobject]@{ ObjectType = 'Azure.DevOps.Group'; ObjectName = 'five-admins'; displayName = 'Project Administrators'; Members = @(1..5 | ForEach-Object { @{ id = "synthetic-$_" } }) }
            [pscustomobject]@{ ObjectType = 'Azure.DevOps.Group'; ObjectName = 'one-admin'; displayName = 'Project Administrators'; Members = @(@{ id = 'synthetic-admin' }) }
        )
        $option = New-PSRuleOption -Configuration @{
            ProjectAdminsMaxMembers = 5; ProjectAdminsMinMembers = 1
            administrativePolicyReference = 'reviewed-access-and-break-glass-v1'
        }
        $raw = @($targets | Invoke-PSRule -Module PSRule.Rules.AzureDevOps -Name 'Azure.DevOps.Groups.ProjectAdmins.*' -Option $option -Culture en -ErrorAction Stop)
        $raw.Count | Should -Be 4
        @($raw | Where-Object Outcome -NE 'Pass').Count | Should -Be 0
        $catalog = Get-AzDevOpsAssessmentCatalog
        @($catalog.Rules | Where-Object { $_.RuleId -like 'Azure.DevOps.Groups.ProjectAdmins.*' -and $_.AssessmentSeverity -eq 'Medium' }).Count | Should -Be 2
    }
}
AfterAll { Remove-Module PSRule.Rules.AzureDevOps -Force }
