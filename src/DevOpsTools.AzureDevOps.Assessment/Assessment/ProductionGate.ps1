function Get-AzDevOpsProductionGateAssessment {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$TargetObject)
    if ($null -eq $TargetObject.Checks) {
        return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'ChecksUnavailable' }
    }
    if (@($TargetObject.Checks).Count -eq 0) {
        return [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'MissingProductionGate' }
    }
    $active = @($TargetObject.Checks | Where-Object { $_.isDisabled -ne $true })
    if ($active.Count -eq 0) {
        return [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'DisabledProductionGate' }
    }
    $incomplete = $false
    foreach ($check in $active) {
        if (-not $check.type.name -or $null -eq $check.settings) { $incomplete = $true; continue }
        if ($check.type.name -eq 'Approval') {
            if ($null -eq $check.settings.approvers) { $incomplete = $true; continue }
            if (@($check.settings.approvers).Count -eq 0) { continue }
        } else {
            $fields = if ($check.settings -is [System.Collections.IDictionary]) { @($check.settings.Keys) } else { @($check.settings.psobject.Properties.Name) }
            if ($fields.Count -eq 0) { $incomplete = $true; continue }
        }
        return [pscustomobject]@{ Outcome = 'Pass'; ReasonCode = 'ConfiguredProductionGate' }
    }
    if ($incomplete) { return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'CheckConfigurationUnavailable' } }
    return [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'InvalidProductionGate' }
}
