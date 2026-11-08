# Production classification is shared between environment, service-connection and release rules.
# Explicit configuration is authoritative. Names are not production evidence.
function Test-AzDevOpsProductionName {
    [CmdletBinding()]
    param([AllowNull()][string]$Name)
    return $false
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
            $expected = @($configured.($type))
            return [pscustomobject]@{ Outcome = if ($name -cin $expected) { 'Production' } else { 'NonProduction' }; ReasonCode = 'ConfiguredProductionScope' }
        }
    }
    foreach ($propertyName in 'isProduction', 'production') {
        $property = $TargetObject.PSObject.Properties[$propertyName]
        if ($null -ne $property -and $property.Value -is [bool]) {
            return [pscustomobject]@{ Outcome = if ($property.Value) { 'Production' } else { 'NonProduction' }; ReasonCode = 'ApiProductionClassification' }
        }
    }
    return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'ProductionClassificationUnavailable' }
}

function Get-AzDevOpsProductionReleaseClassification {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$TargetObject, [object]$Configuration)
    $release = [string]$TargetObject.ObjectName
    $configured = $Configuration.productionReleaseEnvironments
    $isConfigured = if ($null -eq $configured) { $false } elseif ($configured -is [System.Collections.IDictionary]) {
        $configured.Contains($release)
    } else {
        $null -ne $configured.PSObject.Properties[$release]
    }
    if ($isConfigured) {
        $expected = @($configured.($release))
        $matches = @($TargetObject.environments | Where-Object { $_.name -cin $expected })
        return [pscustomobject]@{ Outcome = if ($matches.Count -gt 0) { 'Production' } else { 'NonProduction' }; ReasonCode = 'ConfiguredProductionScope' }
    }
    $environments = @($TargetObject.environments)
    if ($environments.Count -eq 0) { return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'ProductionClassificationUnavailable' } }
    $values = @($environments | ForEach-Object {
        $property = $_.PSObject.Properties['isProduction']
        if ($null -ne $property -and $property.Value -is [bool]) { $property.Value } else { $null }
    })
    if ($values -contains $true) { return [pscustomobject]@{ Outcome = 'Production'; ReasonCode = 'ApiProductionClassification' } }
    if (@($values | Where-Object { $null -eq $_ }).Count -eq 0) { return [pscustomobject]@{ Outcome = 'NonProduction'; ReasonCode = 'ApiProductionClassification' } }
    return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'ProductionClassificationUnavailable' }
}

function Get-AzDevOpsProductionReleaseEnvironments {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$TargetObject, [object]$Configuration)
    $classification = Get-AzDevOpsProductionReleaseClassification -TargetObject $TargetObject -Configuration $Configuration
    if ($classification.Outcome -ne 'Production') { return @() }
    $release = [string]$TargetObject.ObjectName
    $configured = $Configuration.productionReleaseEnvironments
    if ($null -ne $configured -and (($configured -is [System.Collections.IDictionary] -and $configured.Contains($release)) -or
        ($configured -isnot [System.Collections.IDictionary] -and $null -ne $configured.PSObject.Properties[$release]))) {
        return @($TargetObject.environments | Where-Object { $_.name -cin @($configured.($release)) })
    }
    return @($TargetObject.environments | Where-Object { $_.PSObject.Properties['isProduction'].Value -eq $true })
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
