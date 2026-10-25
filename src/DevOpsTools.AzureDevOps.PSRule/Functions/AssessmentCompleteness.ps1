# Private helpers: collection status never enters the assessment target stream.
function Set-AzDevOpsCollectionStatus {
    param (
        [ValidateSet('Empty', 'Partial', 'Unavailable', 'Failed')]
        [string]$Status,
        [string]$ReasonCode
    )

    if ($null -eq $script:collectionStatus) { return }
    $priority = @{ Completed = 0; Empty = 1; Partial = 2; Unavailable = 3; Failed = 4 }
    if ($Status -eq 'Empty' -and $priority[$script:collectionStatus.Status] -gt $priority.Empty) { return }
    if ($priority[$Status] -gt $priority[$script:collectionStatus.Status]) {
        $script:collectionStatus.Status = $Status
    }
    if ($ReasonCode -and $ReasonCode -notin $script:collectionStatus.ReasonCodes) {
        $script:collectionStatus.ReasonCodes += $ReasonCode
    }
}

function Set-AzDevOpsMissingCollectionData {
    param ($Data, [string[]]$RequiredProperties, [string[]]$AllowNullProperties, [switch]$Partial)

    if ($null -eq $script:collectionStatus) { return }
    if ($null -eq $Data) {
        $status = if ($Partial) { 'Partial' } else { 'Unavailable' }
        Set-AzDevOpsCollectionStatus -Status $status -ReasonCode MissingRequiredData
        return
    }
    if (-not $RequiredProperties) { return }
    $properties = if ($Data -is [System.Collections.IDictionary]) { @($Data.Keys) } else { @($Data.PSObject.Properties.Name) }
    $missing = @()
    foreach ($property in $RequiredProperties) {
        if ($property -notin $properties -or ($null -eq $Data.$property -and $property -notin $AllowNullProperties)) {
            $missing += $property
        }
    }
    if ($missing.Count) {
        $status = if (-not $Partial -and $missing.Count -eq $RequiredProperties.Count) { 'Unavailable' } else { 'Partial' }
        Set-AzDevOpsCollectionStatus -Status $status -ReasonCode MissingRequiredData
    }
}

function Get-AzDevOpsCollectionSummary {
    param ([object[]]$Records)

    $incomplete = @($Records | Where-Object { $_.Status -notin 'Completed', 'Empty' })
    if ($incomplete.Count -eq 0) { return 'Complete' }
    if (@($Records | Where-Object { $_.Status -in 'Completed', 'Empty', 'Partial' }).Count -eq 0) { return 'Unavailable' }
    return 'Partial'
}

function Assert-AzDevOpsCompletenessReportPath {
    param ([string]$OutputPath, [string]$CompletenessReportPath)

    if (-not $CompletenessReportPath) { return }
    $outputDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath).TrimEnd([char[]]@('/', '\'))
    $reportPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CompletenessReportPath)
    $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    if ($reportPath.Equals($outputDirectory, $comparison) -or $reportPath.StartsWith($outputDirectory + [System.IO.Path]::DirectorySeparatorChar, $comparison)) {
        throw 'CompletenessReportPath must be outside the assessment export directory.'
    }
}

function Complete-AzDevOpsAssessmentExport {
    param ($Report, [string]$CompletenessReportPath, [switch]$Strict)

    $records = @()
    if ($Report.Contains('OrganizationCollection')) {
        $Report.OrganizationCollection.Status = Get-AzDevOpsCollectionSummary -Records $Report.OrganizationCollection.Collectors
        $records += $Report.OrganizationCollection.Collectors
    }
    foreach ($project in $Report.Projects) {
        $project.Status = Get-AzDevOpsCollectionSummary -Records $project.Collectors
        $records += $project.Collectors
    }
    if ($Report.Contains('ProjectDiscovery') -and ($Report.Projects.Count -eq 0 -or $Report.ProjectDiscovery.Status -notin 'Completed', 'Empty')) {
        $records += $Report.ProjectDiscovery
    }
    $Report.Status = Get-AzDevOpsCollectionSummary -Records $records
    if ($CompletenessReportPath) {
        $Report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $CompletenessReportPath -Encoding utf8 -ErrorAction Stop
    }
    if ($Report.Status -ne 'Complete') {
        $commands = @($records | Where-Object { $_.Status -notin 'Completed', 'Empty' } | ForEach-Object { $_.Command } | Select-Object -Unique)
        $message = "Assessment collection is incomplete: $($commands -join ', ')."
        if ($Strict) { throw $message }
        Write-Warning $message
    }
}
