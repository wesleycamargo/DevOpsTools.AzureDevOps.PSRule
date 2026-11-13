function Export-AzDevOpsAssessmentRun {
    <#
    .SYNOPSIS
    Write versioned per-project assessment projections alongside organization-wide SARIF.
    .DESCRIPTION
    Reuses detailed results with file provenance from the original -Outcome All evaluation.
    Exported target payloads are read locally and never included in the output report.
    .PARAMETER HtmlOutputPath
    Optionally write a self-contained project assessment HTML report alongside JSON.
    Does not change PSRule output formats or include organization-wide SARIF findings.
    .PARAMETER CollectionStatusPath
    Collection completeness JSON. Required when HtmlOutputPath is specified.
    HTML is generated only for complete collection.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Result,
        [Parameter(Mandatory)][string]$ExportPath,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)][string]$Organization,
        [Parameter(Mandatory)][string]$SourceRevision,
        [string]$Baseline = 'Baseline.Default',
        [System.Collections.IDictionary]$Configuration = @{},
        [string]$HtmlOutputPath,
        [string]$CollectionStatusPath
    )
    if ($HtmlOutputPath -and -not $CollectionStatusPath) {
        throw 'CollectionStatusPath is required when HtmlOutputPath is specified.'
    }
    $projects = @()
    foreach ($directory in Get-ChildItem -LiteralPath $ExportPath -Directory) {
        $prefix = $directory.FullName + [IO.Path]::DirectorySeparatorChar
        $projectResults = @($Result | Where-Object {
            @($_.Source | Where-Object { $_.File -and [IO.Path]::GetFullPath($_.File).StartsWith($prefix, [StringComparison]::Ordinal) }).Count -gt 0
        })
        $targets = @(Get-PSRuleTarget -InputPath $prefix)
        if ($targets.Count -gt 0 -and $projectResults.Count -eq 0) { throw 'Exported targets have no detailed rule results with matching source provenance.' }
        $projects += ConvertTo-AzDevOpsAssessment -Result $projectResults -TargetObject $targets -ScopeId "$Organization/$($directory.Name)" -Baseline $Baseline -Configuration $Configuration
    }
    $catalog = Get-AzDevOpsAssessmentCatalog
    $report = [pscustomobject][ordered]@{
        SchemaVersion = 1; RuleSetVersion = $catalog.RuleSetVersion; SeverityPolicyVersion = $catalog.SeverityPolicyVersion
        SourceRevision = $SourceRevision; Organization = $Organization; Baseline = $Baseline; Projects = $projects
    }
    $report | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $OutputPath -Encoding utf8
    if ($HtmlOutputPath) {
        Export-AzDevOpsAssessmentHtmlReport -Assessment $report -CollectionStatusPath $CollectionStatusPath -OutputPath $HtmlOutputPath
    }
    return $report
}
Export-ModuleMember -Function Export-AzDevOpsAssessmentRun
