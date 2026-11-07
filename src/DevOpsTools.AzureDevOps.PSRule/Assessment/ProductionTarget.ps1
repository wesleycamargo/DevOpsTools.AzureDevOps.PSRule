# Production classification is shared between environment, service-connection and release rules.
# Explicit configuration is authoritative for a target type or release definition.
function Test-AzDevOpsProductionName {
    [CmdletBinding()]
    param([AllowNull()][string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return $false }
    # Never assume 'main' or 'master' is a production environment.
    return $Name -match '(?i)(^|[._\s-])(production|prod|prd|live)($|[._\s-])'
}

function Test-AzDevOpsProductionTarget {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$TargetObject, [object]$Configuration)
    $type = [string]$TargetObject.ObjectType
    $name = [string]$TargetObject.ObjectName
    $configured = $Configuration.productionTargets
    if ($null -ne $configured) {
        $isConfigured = if ($configured -is [System.Collections.IDictionary]) {
            $configured.Contains($type)
        } else {
            $null -ne $configured.PSObject.Properties[$type]
        }
        if ($isConfigured) {
            return $name -cin @($configured.($type))
        }
    }
    return Test-AzDevOpsProductionName -Name $TargetObject.name
}

function Get-AzDevOpsProductionReleaseEnvironments {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$TargetObject, [object]$Configuration)
    $release = [string]$TargetObject.ObjectName
    $configured = $Configuration.productionReleaseEnvironments
    $isConfigured = $false
    if ($null -ne $configured) {
        $isConfigured = if ($configured -is [System.Collections.IDictionary]) {
            $configured.Contains($release)
        } else {
            $null -ne $configured.PSObject.Properties[$release]
        }
    }
    if ($isConfigured) {
        $expected = @($configured.($release))
        return @($TargetObject.environments | Where-Object { $_.name -cin $expected })
    }
    return @($TargetObject.environments | Where-Object { Test-AzDevOpsProductionName -Name $_.name })
}

function Get-AzDevOpsProductionBranchAssessment {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$TargetObject)
    if ($null -eq $TargetObject.Checks) {
        return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'ChecksUnavailable' }
    }
    $branchChecks = @($TargetObject.Checks | Where-Object {
        $_.type.name -eq 'Branch control' -or $_.settings.displayName -eq 'Branch control'
    })
    if ($branchChecks.Count -eq 0) {
        return [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'MissingProductionBranchControl' }
    }
    $incomplete = $false
    foreach ($check in $branchChecks) {
        if ($check.isDisabled -eq $true) { continue }
        $allowed = $check.settings.inputs.allowedBranches
        if ($null -eq $allowed) { $incomplete = $true; continue }
        $names = @($allowed | ForEach-Object { [string]$_ -split '[,;]' } |
            ForEach-Object { $_.Trim() } | Where-Object { $_ })
        $unrestrictedOrInvalid = @($names | Where-Object {
            $_ -cnotmatch '^refs/heads/(?!\*+$)[^,;\s]+$'
        })
        if ($names.Count -gt 0 -and $unrestrictedOrInvalid.Count -eq 0) {
            return [pscustomobject]@{ Outcome = 'Pass'; ReasonCode = 'RestrictedProductionBranches' }
        }
    }
    if ($incomplete) {
        return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'BranchCheckConfigurationUnavailable' }
    }
    return [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'ProductionBranchRestrictionMissingOrDisabled' }
}
