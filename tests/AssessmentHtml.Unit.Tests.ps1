BeforeAll {
    Import-Module "$PSScriptRoot/../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1" -Force
}

Describe 'Static assessment HTML' -Tag 'Unit' {
    It 'renders a portable project report from the existing projection' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule -Parameters @{ Root = $TestDrive } {
            param($Root)
            $status = Join-Path $Root 'collection-status.json'
            '{"Status":"Complete"}' | Set-Content -LiteralPath $status
            $report = [pscustomobject]@{
                Organization = 'fixture-org'; SourceRevision = 'fixture-revision'
                Baseline = 'Baseline.Default'; RuleSetVersion = 'fixture-rules'
                SeverityPolicyVersion = 'fixture-severity'
                Projects = @([pscustomobject]@{
                    ScopeId = 'fixture-org/project-a'
                    Summary = [pscustomobject]@{ SecurityScore = $null }
                    Findings = @(
                        [pscustomobject]@{ RuleId = 'rule.pass'; TargetName = 'target-a'; Outcome = 'Pass' }
                        [pscustomobject]@{ RuleId = 'rule.fail'; TargetName = 'target-b'; Outcome = 'Fail'; ReasonCode = 'MissingPolicy'; AssessmentSeverity = $null }
                        [pscustomobject]@{ RuleId = 'rule.unknown'; TargetName = 'target-c'; Outcome = 'Unknown'; ReasonCode = 'EvidenceUnavailable' }
                        [pscustomobject]@{ RuleId = 'rule.na'; TargetName = 'target-d'; Outcome = 'NotApplicable' }
                    )
                })
            }
            $before = $report | ConvertTo-Json -Depth 20
            $output = Join-Path $Root 'psrule-report.html'
            Export-AzDevOpsAssessmentHtmlReport -Assessment $report -CollectionStatusPath $status -OutputPath $output
            $html = Get-Content -LiteralPath $output -Raw
            $html | Should -Match '<!doctype html>'
            $html | Should -Match 'Azure DevOps project assessment'
            $html | Should -Match 'fixture-org/project-a'
            $html | Should -Match 'fixture-revision'
            $html | Should -Match 'Collection status: Complete'
            $html | Should -Match 'Pass: 1; Fail: 1; Unknown: 1; NotApplicable: 1'
            $html | Should -Match 'Evaluated pass rate: 50.00%'
            $html | Should -Match 'SecurityScore: Unavailable'
            $html | Should -Match 'Unclassified'
            $html | Should -Match 'rule.fail'
            $html | Should -Match 'EvidenceUnavailable'
            $html | Should -Not -Match 'rule.pass|rule.na'
            $html | Should -Not -Match '<script|<link|<iframe|<img|https?://|\ssrc='
            ($report | ConvertTo-Json -Depth 20) | Should -Be $before
        }
    }
    It 'encodes all display values without copying raw evidence' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule -Parameters @{ Root = $TestDrive } {
            param($Root)
            $status = Join-Path $Root 'status.json'
            '{"Status":"Complete"}' | Set-Content -LiteralPath $status
            $marker = '<script>alert("x")</script>&'
            $report = [pscustomobject]@{
                Organization = $marker; SourceRevision = $marker; Baseline = $marker
                RuleSetVersion = $marker; SeverityPolicyVersion = $marker
                Projects = @([pscustomobject]@{
                    ScopeId = $marker; Summary = [pscustomobject]@{ SecurityScore = $null }
                    Findings = @([pscustomobject]@{
                        RuleId = $marker; TargetName = $marker; Outcome = 'Fail'
                        ReasonCode = $marker; AssessmentSeverity = $marker
                        RawReasons = @('private-evidence-marker'); RawPayload = 'private-payload-marker'
                    })
                })
            }
            $output = Join-Path $Root 'encoded.html'
            Export-AzDevOpsAssessmentHtmlReport $report $status $output
            $html = Get-Content -LiteralPath $output -Raw
            $html | Should -Match '&lt;script&gt;alert\(&quot;x&quot;\)&lt;/script&gt;&amp;'
            $html | Should -Not -Match '<script>|private-evidence-marker|private-payload-marker'
        }
    }
    It 'shows unavailable rather than compliance for no project results' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule -Parameters @{ Root = $TestDrive } {
            param($Root)
            $status = Join-Path $Root 'status.json'
            '{"Status":"Complete"}' | Set-Content -LiteralPath $status
            $output = Join-Path $Root 'empty.html'
            Export-AzDevOpsAssessmentHtmlReport -Assessment ([pscustomobject]@{ Projects = @() }) -CollectionStatusPath $status -OutputPath $output
            $html = Get-Content -LiteralPath $output -Raw
            $html | Should -Match 'No project assessment results are available'
            $html | Should -Match 'Evaluated pass rate: Unavailable'
            $html | Should -Not -Match '100.00%'
        }
    }

    It 'shows an explicit empty findings state and preserves a real zero score' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule -Parameters @{ Root = $TestDrive } {
            param($Root)
            $status = Join-Path $Root 'status.json'
            '{"Status":"Complete"}' | Set-Content -LiteralPath $status
            $output = Join-Path $Root 'passed.html'
            $report = [pscustomobject]@{ Projects = @([pscustomobject]@{
                ScopeId = 'fixture/project'; Findings = @(); Summary = [pscustomobject]@{ SecurityScore = 0 }
            }) }
            Export-AzDevOpsAssessmentHtmlReport $report $status $output
            $html = Get-Content -LiteralPath $output -Raw
            $html | Should -Match 'No failing or unknown project findings'
            $html | Should -Match 'SecurityScore: 0'
        }
    }

    It 'does not generate a success report from incomplete collection' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule -Parameters @{ Root = $TestDrive } {
            param($Root)
            $status = Join-Path $Root 'status.json'
            '{"Status":"Partial"}' | Set-Content -LiteralPath $status
            $output = Join-Path $Root 'partial.html'
            { Export-AzDevOpsAssessmentHtmlReport -Assessment ([pscustomobject]@{ Projects = @() }) -CollectionStatusPath $status -OutputPath $output } | Should -Throw '*requires complete collection*'
            Test-Path -LiteralPath $output | Should -BeFalse
        }
    }

    It 'wraps long report identifiers on narrow screens' {
        InModuleScope DevOpsTools.AzureDevOps.PSRule -Parameters @{ Root = $TestDrive } {
            param($Root)
            $status = Join-Path $Root 'status.json'
            '{"Status":"Complete"}' | Set-Content -LiteralPath $status
            $output = Join-Path $Root 'narrow.html'
            $report = [pscustomobject]@{ SourceRevision = ('a' * 40); Projects = @() }
            Export-AzDevOpsAssessmentHtmlReport $report $status $output
            $html = Get-Content -LiteralPath $output -Raw
            $html | Should -Match 'body\s*\{[^}]*overflow-wrap:\s*anywhere'
            $html | Should -Match 'th\s*\{[^}]*white-space:\s*nowrap'
        }
    }
}

AfterAll { Remove-Module DevOpsTools.AzureDevOps.PSRule -Force }
