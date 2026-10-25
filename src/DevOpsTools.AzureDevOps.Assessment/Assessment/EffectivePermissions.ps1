# Evaluate a complete, ordered ACL path and identity graph against an approved policy.
function Get-AzDevOpsEffectivePermissionAssessment {
    [CmdletBinding()]
    param([object]$Evidence, [object]$Policy)

    $unknown = [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'PermissionEvidenceUnavailable'; Violations = @() }
    if ($null -eq $Policy -or -not $Policy.Reference -or $null -eq $Policy.SensitiveMask -or $null -eq $Policy.Allowed) {
        return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'PermissionPolicyUnavailable'; Violations = @() }
    }
    if ($null -eq $Evidence -or $Evidence.SchemaVersion -ne 1 -or $Evidence.Status -ne 'Complete' -or
        $Evidence.ScopeComplete -ne $true -or $Evidence.IdentitiesComplete -ne $true -or
        $Evidence.AdministratorsComplete -ne $true -or @($Evidence.Acls).Count -eq 0 -or
        $Evidence.NamespaceId -ne $Policy.NamespaceId -or -not $Evidence.Token -or
        $Evidence.Acls[-1].token -ne $Evidence.Token) { return $unknown }

    $identities = @{}
    foreach ($identity in $Evidence.Identities) {
        if (-not $identity.descriptor -or $null -eq $identity.isContainer -or
            $null -eq $identity.bypassMask -or $identities.ContainsKey($identity.descriptor)) { return $unknown }
        if ($identity.isContainer -and $null -eq $identity.members) { return $unknown }
        $identities[$identity.descriptor] = $identity
    }
    # Resolve nested groups once per principal. Cycles are valid; incomplete references are not.
    $memberships = @{}
    foreach ($identity in $Evidence.Identities) {
        foreach ($member in $identity.members) {
            if (-not $identities.ContainsKey([string]$member)) { return $unknown }
            if (-not $memberships.ContainsKey([string]$member)) { $memberships[[string]$member] = @() }
            $memberships[[string]$member] += $identity.descriptor
        }
    }
    $grants = @{}
    foreach ($acl in $Evidence.Acls) {
        if ($null -eq $acl.inheritPermissions -or $null -eq $acl.acesDictionary) { return $unknown }
        if (-not $acl.inheritPermissions) { $grants = @{} }
        $aces = if ($acl.acesDictionary -is [System.Collections.IDictionary]) { @($acl.acesDictionary.Values) } else { @($acl.acesDictionary.psobject.Properties.Value) }
        foreach ($ace in $aces) {
            if (-not $identities.ContainsKey([string]$ace.descriptor) -or $null -eq $ace.allow -or $null -eq $ace.deny) { return $unknown }
            $prior = $grants[$ace.descriptor]
            $explicit = [long]$ace.allow -bor [long]$ace.deny
            # Explicit entries override inherited entries for this identity and permission.
            $grants[$ace.descriptor] = @{
                Allow = ([long]$prior.Allow -band (-bnot $explicit)) -bor [long]$ace.allow
                Deny = ([long]$prior.Deny -band (-bnot $explicit)) -bor [long]$ace.deny
            }
        }
    }
    $allowed = if ($Policy.Allowed -is [System.Collections.IDictionary]) { $Policy.Allowed } else {
        $map = @{}; foreach ($property in $Policy.Allowed.psobject.Properties) { $map[$property.Name] = $property.Value }; $map
    }
    foreach ($descriptor in $allowed.Keys) {
        if (-not $identities.ContainsKey([string]$descriptor)) { return $unknown }
    }
    $violations = @()
    foreach ($identity in $Evidence.Identities) {
        if ($identity.isContainer) { continue }
        $closure = @{}
        $pending = [System.Collections.Generic.Queue[string]]::new()
        $pending.Enqueue($identity.descriptor)
        while ($pending.Count -gt 0) {
            $descriptor = $pending.Dequeue()
            if ($closure.ContainsKey($descriptor)) { continue }
            $closure[$descriptor] = $true
            foreach ($group in $memberships[$descriptor]) { $pending.Enqueue($group) }
        }
        [long]$allow = 0; [long]$deny = 0; [long]$authorized = 0; [long]$bypass = 0
        foreach ($descriptor in $closure.Keys) {
            $allow = $allow -bor [long]$grants[$descriptor].Allow
            $deny = $deny -bor [long]$grants[$descriptor].Deny
            $authorized = $authorized -bor [long]$allowed[$descriptor]
            $bypass = $bypass -bor [long]$identities[$descriptor].bypassMask
        }
        $effective = ($allow -band (-bnot $deny)) -bor $bypass
        $excess = $effective -band [long]$Policy.SensitiveMask -band (-bnot $authorized)
        if ($excess -ne 0) { $violations += [pscustomobject]@{ Descriptor = $identity.descriptor; Mask = $excess } }
    }
    if ($violations.Count -gt 0) {
        return [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'UnauthorizedEffectivePermission'; Violations = $violations }
    }
    return [pscustomobject]@{ Outcome = 'Pass'; ReasonCode = 'EffectivePermissionsAuthorized'; Violations = @() }
}
