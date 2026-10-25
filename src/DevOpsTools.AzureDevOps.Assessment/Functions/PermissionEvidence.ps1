function Get-AzDevOpsPermissionEvidence {
    <#
    .SYNOPSIS
    Collect an ACL ancestry and identity graph for an effective-permission assessment.
    .DESCRIPTION
    AdministrativeBypass is a reviewed descriptor-to-mask map of platform bypass privileges,
    not an allow list. Its provenance is required before collection can be complete.
    Unknown namespaces, incomplete identity responses, and API failures remain unavailable.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$NamespaceId,
        [Parameter(Mandatory)][string]$Token,
        [System.Collections.IDictionary]$AdministrativeBypass,
        [string]$AdministrativeEvidenceReference,
        [string[]]$AdditionalDescriptors = @()
    )
    if ($null -eq $script:connection) { throw 'Not connected to Azure DevOps. Run Connect-AzDevOps first.' }
    $evidence = [ordered]@{
        SchemaVersion = 1; Status = 'Partial'; NamespaceId = $NamespaceId.ToString(); Token = $Token
        ScopeComplete = $false; IdentitiesComplete = $false; AdministratorsComplete = $false
        AdministrativeEvidenceReference = $AdministrativeEvidenceReference
        CollectedAt = [DateTime]::UtcNow.ToString('o'); Acls = @(); Identities = @(); ReasonCode = 'CollectionIncomplete'
    }
    if ($null -eq $AdministrativeBypass -or -not $AdministrativeEvidenceReference) {
        $evidence.ReasonCode = 'AdministrativeEvidenceUnavailable'
        return [pscustomobject]$evidence
    }
    $organization = $script:connection.Organization
    $header = $script:connection.GetHeader()
    try {
        $response = Invoke-RestMethod -Uri "https://dev.azure.com/$organization/_apis/securitynamespaces/$($NamespaceId)?api-version=7.1" -Headers $header -Method Get -ErrorAction Stop
        $namespaces = @($response.value | Where-Object namespaceId -EQ $NamespaceId.ToString())
        if ($namespaces.Count -ne 1) { throw 'NamespaceUnavailable' }
        $namespace = $namespaces[0]
        if ($namespace.useTokenTranslator -or $null -eq $namespace.structureValue) { throw 'UnsupportedNamespace' }
        $tokens = @($Token)
        if ($namespace.structureValue -eq 1) {
            if ($namespace.elementLength -ne -1 -or [string]::IsNullOrEmpty($namespace.separatorValue) -or $namespace.separatorValue -eq "`0") { throw 'UnsupportedNamespace' }
            $separator = [string]$namespace.separatorValue
            $tokens = @('')
            $parts = $Token.Split(@($separator), [System.StringSplitOptions]::None)
            for ($index = 0; $index -lt $parts.Count; $index++) { $tokens += ($parts[0..$index] -join $separator) }
        } elseif ($namespace.structureValue -ne 0) { throw 'UnsupportedNamespace' }
        $pending = [System.Collections.Generic.Queue[string]]::new()
        foreach ($descriptor in @($AdministrativeBypass.Keys) + $AdditionalDescriptors) { $pending.Enqueue([string]$descriptor) }
        foreach ($scope in $tokens) {
            $encoded = [Uri]::EscapeDataString($scope)
            $response = Invoke-RestMethod -Uri "https://dev.azure.com/$organization/_apis/accesscontrollists/$($NamespaceId)?token=$encoded&includeExtendedInfo=true&recurse=false&api-version=7.1" -Headers $header -Method Get -ErrorAction Stop
            if ($null -eq $response.value -or $null -eq $response.count -or $response.count -ne @($response.value).Count) { throw 'AclResponseIncomplete' }
            $matches = @($response.value | Where-Object token -EQ $scope)
            if ($matches.Count -gt 1) { throw 'AclResponseAmbiguous' }
            $acl = if ($matches.Count -eq 1) { $matches[0] } else {
                # A successful empty ACL query is an unset scope, inheriting its parent.
                [pscustomobject]@{ token = $scope; inheritPermissions = $true; acesDictionary = [pscustomobject]@{} }
            }
            if ($null -eq $acl.acesDictionary -or $null -eq $acl.inheritPermissions) { throw 'AclResponseIncomplete' }
            $evidence.Acls += $acl
            foreach ($ace in $acl.acesDictionary.psobject.Properties.Value) { $pending.Enqueue([string]$ace.descriptor) }
        }
        $evidence.ScopeComplete = $true
        $seen = @{}
        while ($pending.Count -gt 0) {
            $descriptor = $pending.Dequeue()
            if ($seen.ContainsKey($descriptor)) { continue }
            $seen[$descriptor] = $true
            $encoded = [Uri]::EscapeDataString($descriptor)
            $response = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$organization/_apis/identities?descriptors=$encoded&queryMembership=Direct&api-version=7.1" -Headers $header -Method Get -ErrorAction Stop
            $identities = @($response.value | Where-Object descriptor -EQ $descriptor)
            if ($identities.Count -ne 1 -or $null -eq $identities[0].isContainer) { throw 'IdentityResponseIncomplete' }
            $identity = $identities[0]
            if ($identity.isContainer -and $null -eq $identity.members) { throw 'MembershipUnavailable' }
            $members = @()
            foreach ($member in $identity.members) {
                $memberDescriptor = if ($member -is [string]) { $member } elseif ($member.identityType -and $member.identifier) { "$($member.identityType);$($member.identifier)" } else { throw 'MembershipUnavailable' }
                $members += $memberDescriptor
                $pending.Enqueue($memberDescriptor)
            }
            $evidence.Identities += [pscustomobject]@{
                descriptor = $descriptor; isContainer = $identity.isContainer; members = $members
                bypassMask = [long]$AdministrativeBypass[$descriptor]
            }
        }
        $evidence.IdentitiesComplete = $true
        $evidence.AdministratorsComplete = $true
        $evidence.Status = 'Complete'
        $evidence.ReasonCode = 'Collected'
    }
    catch {
        # Never persist API exception messages: they can contain organization or identity data.
        $evidence.ReasonCode = 'PermissionCollectionUnavailable'
        Set-AzDevOpsCollectionStatus -Status Partial -ReasonCode MissingRequiredData
    }
    return [pscustomobject]$evidence
}
Export-ModuleMember -Function Get-AzDevOpsPermissionEvidence
