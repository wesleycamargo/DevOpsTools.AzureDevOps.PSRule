function ConvertTo-AzDevOpsNen7510Status {
    param([string[]]$Outcomes)

    if ($Outcomes -contains 'Fail') { return 'Non-compliant' }
    if ($Outcomes.Count -gt 0 -and @($Outcomes | Where-Object { $_ -ne 'Pass' }).Count -eq 0) { return 'Compliant' }
    return 'Not assessed'
}

function Export-AzDevOpsNen7510Pilot {
    <#
    .SYNOPSIS
    Publish the NEN 7510 default-branch protection pilot for one Team Project.
    .DESCRIPTION
    Reuses the findings from Export-AzDevOpsAssessmentRun and queries additional Git
    permission evidence with the current read-only Azure DevOps connection.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Assessment,
        [Parameter(Mandatory)][string]$ExportPath,
        [Parameter(Mandatory)][string]$PolicyPath,
        [Parameter(Mandatory)][string]$OutputDirectory
    )

    if ($null -eq $script:connection) { throw 'Not connected to Azure DevOps. Run Connect-AzDevOps first.' }
    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) { throw 'The NEN 7510 pilot policy file was not found.' }
    $policyContent = Get-Content -LiteralPath $PolicyPath -Raw -ErrorAction Stop
    $policy = $policyContent | ConvertFrom-Json -ErrorAction Stop
    if ($policy.Project -isnot [string] -or [string]::IsNullOrWhiteSpace($policy.Project) -or
        $policy.ControlReference -isnot [string] -or [string]::IsNullOrWhiteSpace($policy.ControlReference) -or
        $policy.AllowedBypass -isnot [pscustomobject]) {
        throw 'The NEN 7510 pilot policy requires Project, ControlReference and an AllowedBypass object.'
    }
    foreach ($entry in $policy.AllowedBypass.psobject.Properties) {
        if ([string]::IsNullOrWhiteSpace($entry.Name) -or $entry.Value -isnot [array] -or $entry.Value.Count -eq 0 -or
            @($entry.Value | Where-Object { $_ -notin 'PolicyExempt', 'PullRequestBypassPolicy' }).Count -gt 0) {
            throw 'Every AllowedBypass entry must map an identity descriptor to at least one supported permission.'
        }
    }

    $mapping = Get-Content -LiteralPath "$PSScriptRoot/../Assessment/nen7510.json" -Raw | ConvertFrom-Json
    $scopeId = "$($Assessment.Organization)/$($policy.Project)"
    $project = $Assessment.Projects | Where-Object ScopeId -EQ $scopeId
    $directory = Get-ChildItem -LiteralPath $ExportPath -Directory | Where-Object Name -EQ $policy.Project
    $repositories = @()
    if ($null -ne $project -and $null -ne $directory) {
        $prefix = $directory.FullName + [IO.Path]::DirectorySeparatorChar
        $repositories = @(Get-PSRuleTarget -InputPath $prefix | Where-Object ObjectType -EQ 'Azure.DevOps.Repo')
    }

    $context = @{ Acls = @{}; Identities = @{} }
    $branches = @(foreach ($repository in ($repositories | Sort-Object ObjectName)) {
        $targetName = "$($repository.ObjectType)/$($repository.ObjectName)"
        $checks = @(foreach ($ruleId in $mapping.Control.RuleIds) {
            $findings = @($project.Findings | Where-Object { $_.TargetName -eq $targetName -and $_.RuleId -eq $ruleId })
            if ($repository.defaultBranch -and $findings.Count -eq 1) {
                [pscustomobject]@{ RuleId = $ruleId; Outcome = $findings[0].Outcome; Reason = $findings[0].ReasonCode }
            } else {
                [pscustomobject]@{ RuleId = $ruleId; Outcome = 'Unknown'; Reason = 'Default branch or rule result unavailable' }
            }
        })
        $bypass = Get-AzDevOpsGitBranchBypassAssessment -Repository $repository -Context $context -AllowedBypass $policy.AllowedBypass
        $outcomes = @($checks.Outcome) + @($bypass.Outcome)
        [pscustomobject]@{
            Repository = $repository.name
            Branch = $repository.defaultBranch
            Status = ConvertTo-AzDevOpsNen7510Status -Outcomes $outcomes
            RuleEvidence = $checks
            Bypass = $bypass
        }
    })

    $status = if ($branches.Status -contains 'Non-compliant') { 'Non-compliant' }
    elseif ($branches.Count -gt 0 -and $branches.Status -notcontains 'Not assessed') { 'Compliant' }
    else { 'Not assessed' }
    $report = [pscustomobject][ordered]@{
        SchemaVersion = $mapping.SchemaVersion
        Profile = $mapping.Profile
        Organization = $Assessment.Organization
        TeamProject = $policy.Project
        SourceRevision = $Assessment.SourceRevision
        RuleSetVersion = $Assessment.RuleSetVersion
        Control = $mapping.Control.Name
        ControlReference = $policy.ControlReference
        PolicyHash = Get-AzDevOpsAssessmentHash -Value $policyContent
        AssessedAt = [DateTime]::UtcNow.ToString('o')
        Status = $status
        CoverageReason = if ($null -eq $project -or $null -eq $directory) { 'Team Project unavailable in the assessment export' }
        elseif ($branches.Count -eq 0) { 'No repositories in the Team Project export' }
        Branches = $branches
    }
    $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'nen7510-results.json') -Encoding utf8

    $summary = @(
        '# NEN 7510 pilot'
        ''
        "Team Project: $(ConvertTo-AzDevOpsNen7510MarkdownText $report.TeamProject)"
        "Control: $($report.Control) ($(ConvertTo-AzDevOpsNen7510MarkdownText $report.ControlReference))"
        "Status: **$status**"
        ''
        'This result covers the default branch configuration checks in the pilot.'
    )
    if ($report.CoverageReason) { $summary += '', $report.CoverageReason }
    if ($branches.Count -gt 0) {
        $summary += '', '| Repository | Default branch | Status | Bypass check |', '| --- | --- | --- | --- |'
        foreach ($branch in $branches) {
            $repositoryCell = ConvertTo-AzDevOpsNen7510MarkdownText $branch.Repository
            $branchCell = ConvertTo-AzDevOpsNen7510MarkdownText $branch.Branch
            $summary += "| $repositoryCell | $branchCell | $($branch.Status) | $($branch.Bypass.Reason) |"
        }
    }
    $summaryPath = Join-Path $OutputDirectory 'nen7510-summary.md'
    $summary | Set-Content -LiteralPath $summaryPath -Encoding utf8
    return $summaryPath
}

function ConvertTo-AzDevOpsNen7510MarkdownText {
    param([string]$Value)

    # Encode punctuation with Markdown meaning and keep each table cell on one line.
    [regex]::Replace(($Value -replace '[\r\n]', ' '), '[^ \p{L}\p{N}./_-]', {
        param($match)
        '&#' + [int][char]$match.Value + ';'
    })
}

Export-ModuleMember -Function Export-AzDevOpsNen7510Pilot
