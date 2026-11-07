Describe 'Dutch branch-policy enforcement help' -Tag Unit {
    It 'documents enabled and blocking enforcement for <Name>' -ForEach @(
        @{ Name = 'AllowSelfApproval' }
        @{ Name = 'CommentResolution' }
        @{ Name = 'EnforceLinkedWorkItems' }
        @{ Name = 'IsEnabled' }
        @{ Name = 'MergeStrategy' }
        @{ Name = 'MinimumReviewers' }
        @{ Name = 'RequireBuild' }
        @{ Name = 'ResetVotes' }
    ) {
        $path = Join-Path $PSScriptRoot "../src/DevOpsTools.AzureDevOps.PSRule/nl/Azure.DevOps.Repos.BranchPolicy$Name.md"
        Test-Path -LiteralPath $path | Should -BeTrue
        $text = Get-Content -LiteralPath $path -Raw
        $text | Should -Match 'ingeschakeld'
        $text | Should -Match 'blokkerend'
        $text | Should -Match 'isEnabled = true'
        $text | Should -Match 'isBlocking = true'
        $text | Should -Match 'adviserende'
        $text | Should -Match '## BEWIJS'
    }
}
