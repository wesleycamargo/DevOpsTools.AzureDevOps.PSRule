BeforeDiscovery {
    $fixtures = @(Get-ChildItem "$PSScriptRoot/fixtures/rules" -Filter '*.json' -File | ForEach-Object {
        @{ FixtureName = $_.BaseName; FixturePath = $_.FullName }
    })
    if ($fixtures.Count -eq 0) { throw 'Synthetic rule fixtures are required.' }
}

BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Assessment with synthetic rule fixtures' -Tag 'Unit' {
    BeforeEach {
        Mock Invoke-RestMethod { throw 'Offline rule evaluation attempted a live API request.' }
        Mock Invoke-WebRequest { throw 'Offline rule evaluation attempted a live API request.' }
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod { throw 'Offline rule evaluation attempted a live API request.' }
        Mock -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-WebRequest { throw 'Offline rule evaluation attempted a live API request.' }
    }

    It 'evaluates passing, failing, missing-field and inapplicable <FixtureName> targets' -ForEach $fixtures {
        $fixture = Get-Content $FixturePath -Raw | ConvertFrom-Json
        $fixture.Cases.Count | Should -Be 4
        $configuration = @{}
        if ($fixture.Configuration) {
            $configuration = $fixture.Configuration | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
        }
        $option = New-PSRuleOption -Configuration $configuration
        $results = @($fixture.Cases.Target | Invoke-PSRule -Module DevOpsTools.AzureDevOps.PSRule -Name $fixture.Rule -Option $option -Culture en)
        $results.Count | Should -Be @($fixture.Cases | Where-Object Outcome -NE 'None').Count

        foreach ($case in $fixture.Cases) {
            $targetName = "$($case.Target.ObjectType)/$($case.Target.ObjectName)"
            $hits = @($results | Where-Object TargetName -EQ $targetName)
            if ($case.Outcome -eq 'None') {
                $hits.Count | Should -Be 0
            }
            else {
                $hits.Count | Should -Be 1
                $hits[0].Outcome | Should -Be $case.Outcome
            }
        }
        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-RestMethod -Times 0 -Exactly
        Should -Invoke -ModuleName DevOpsTools.AzureDevOps.PSRule Invoke-WebRequest -Times 0 -Exactly
    }
}
