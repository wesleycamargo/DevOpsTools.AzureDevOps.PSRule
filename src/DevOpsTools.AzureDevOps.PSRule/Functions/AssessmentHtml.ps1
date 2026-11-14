# Private renderer: presentation only, no Azure calls or rule re-evaluation.
function Export-AzDevOpsAssessmentHtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Assessment,
        [Parameter(Mandatory)][string]$CollectionStatusPath,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $status = Get-Content -LiteralPath $CollectionStatusPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($status.Status -ne 'Complete') {
        throw 'HTML assessment requires complete collection.'
    }
    $encode = { param($Value) [System.Net.WebUtility]::HtmlEncode([string]$Value) }
    $counts = {
        param([object[]]$Findings)
        $pass = @($Findings | Where-Object Outcome -EQ 'Pass').Count
        $fail = @($Findings | Where-Object Outcome -EQ 'Fail').Count
        $unknown = @($Findings | Where-Object Outcome -EQ 'Unknown').Count
        $notApplicable = @($Findings | Where-Object Outcome -EQ 'NotApplicable').Count
        $rate = 'Unavailable'
        if (($pass + $fail) -gt 0) {
            $rate = (100.0 * $pass / ($pass + $fail)).ToString('F2', [Globalization.CultureInfo]::InvariantCulture) + '%'
        }
        "<p>Pass: $pass; Fail: $fail; Unknown: $unknown; NotApplicable: $notApplicable</p><p>Evaluated pass rate: $rate</p>"
    }
    $body = [System.Text.StringBuilder]::new()
    [void]$body.AppendLine('<h1>Azure DevOps project assessment</h1>')
    foreach ($name in 'Organization', 'SourceRevision', 'Baseline', 'RuleSetVersion', 'SeverityPolicyVersion') {
        [void]$body.AppendLine("<p>${name}: $(& $encode $Assessment.$name)</p>")
    }
    [void]$body.AppendLine("<p>Collection status: $(& $encode $status.Status)</p>")
    [void]$body.AppendLine('<p>This report covers project projections only. Organization-wide findings are excluded here; review the companion PSRule output. Missing evidence is not a pass. Evaluated pass rate excludes Unknown and NotApplicable and is not a security score.</p>')
    $projects = @($Assessment.Projects | Where-Object { $null -ne $_ })
    $findings = @($projects | ForEach-Object { $_.Findings } | Where-Object { $null -ne $_ })
    [void]$body.AppendLine('<h2>Project diagnostic totals</h2>')
    [void]$body.AppendLine((& $counts $findings))
    if ($projects.Count -eq 0) {
        [void]$body.AppendLine('<p>No project assessment results are available.</p>')
    }
    foreach ($project in $projects | Sort-Object ScopeId) {
        [void]$body.AppendLine("<section><h2>$(& $encode $project.ScopeId)</h2>")
        [void]$body.AppendLine((& $counts @($project.Findings)))
        $score = if ($null -eq $project.Summary.SecurityScore) { 'Unavailable' } else { [string]$project.Summary.SecurityScore }
        [void]$body.AppendLine("<p>SecurityScore: $(& $encode $score)</p>")
        $attention = @($project.Findings | Where-Object { $_.Outcome -in 'Fail', 'Unknown' } | Sort-Object RuleId, TargetName)
        if ($attention.Count -eq 0) {
            [void]$body.AppendLine('<p>No failing or unknown project findings.</p>')
        }
        else {
            [void]$body.AppendLine('<table><caption>Failing and unknown findings</caption><thead><tr><th scope="col">Rule</th><th scope="col">Target</th><th scope="col">Outcome</th><th scope="col">Severity</th><th scope="col">Reason code</th></tr></thead><tbody>')
            foreach ($finding in $attention) {
                $severity = if ($finding.AssessmentSeverity) { $finding.AssessmentSeverity } else { 'Unclassified' }
                [void]$body.AppendLine("<tr><td>$(& $encode $finding.RuleId)</td><td>$(& $encode $finding.TargetName)</td><td>$(& $encode $finding.Outcome)</td><td>$(& $encode $severity)</td><td>$(& $encode $finding.ReasonCode)</td></tr>")
            }
            [void]$body.AppendLine('</tbody></table>')
        }
        [void]$body.AppendLine('</section>')
    }
    $html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Azure DevOps project assessment</title>
<style>
body { font-family: system-ui, sans-serif; margin: 2rem; color: #17202a; background: #fff; overflow-wrap: anywhere; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #bfc9ca; padding: .5rem; text-align: left; vertical-align: top; overflow-wrap: anywhere; }
th { white-space: nowrap; }
caption { text-align: left; font-weight: bold; margin-bottom: .5rem; }
section { margin-top: 2rem; }
@media (max-width: 640px) { body { margin: .75rem; } table { display: block; overflow-x: auto; } }
</style>
</head>
<body>
$body
</body>
</html>
"@
    Set-Content -LiteralPath $OutputPath -Value $html -Encoding utf8 -ErrorAction Stop
}
