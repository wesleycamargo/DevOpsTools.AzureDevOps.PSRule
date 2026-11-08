# Evaluate direct ACL grants against an approved namespace-specific policy.
function Get-AzDevOpsEffectivePermissionAssessment {
    [CmdletBinding()]
    param([object]$Evidence, [object]$Policy)

    $unknown = [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'PermissionEvidenceUnavailable'; Violations = @() }
    if ($null -eq $Policy -or -not $Policy.Reference -or $null -eq $Policy.SensitiveMask -or $null -eq $Policy.Allowed) {
        return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'PermissionPolicyUnavailable'; Violations = @() }
    }
    if ($null -eq $Evidence -or $Evidence.SchemaVersion -ne 1 -or $Evidence.NamespaceId -ne $Policy.NamespaceId -or -not $Evidence.Token) {
        return $unknown
    }

    $acls = @($Evidence.Acls | Where-Object { $_.token -eq $Evidence.Token })
    if ($acls.Count -ne 1) { return $unknown }
    $acl = $acls[0]
    if ($null -eq $acl.acesDictionary) { return $unknown }
    $aces = if ($acl.acesDictionary -is [System.Collections.IDictionary]) { @($acl.acesDictionary.Values) } else { @($acl.acesDictionary.psobject.Properties.Value) }
    $allowed = if ($Policy.Allowed -is [System.Collections.IDictionary]) { $Policy.Allowed } else {
        $map = @{}; foreach ($property in $Policy.Allowed.psobject.Properties) { $map[$property.Name] = $property.Value }; $map
    }

    $violations = @()
    foreach ($ace in $aces) {
        if (-not $ace.descriptor -or $null -eq $ace.allow -or $null -eq $ace.deny) { return $unknown }
        [long]$authorized = if ($allowed.ContainsKey([string]$ace.descriptor)) { $allowed[[string]$ace.descriptor] } else { 0 }
        [long]$direct = [long]$ace.allow -band (-bnot [long]$ace.deny)
        [long]$excess = $direct -band [long]$Policy.SensitiveMask -band (-bnot $authorized)
        if ($excess -ne 0) { $violations += [pscustomobject]@{ Descriptor = $ace.descriptor; Mask = $excess } }
    }
    # A confirmed direct grant remains a finding even if unrelated collection work failed.
    if ($violations.Count -gt 0) {
        return [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'UnauthorizedDirectPermission'; Violations = $violations }
    }

    if ($Evidence.Status -ne 'Complete' -or $Evidence.ScopeComplete -ne $true) { return $unknown }
    return [pscustomobject]@{ Outcome = 'Pass'; ReasonCode = 'DirectPermissionsAuthorized'; Violations = @() }
}
