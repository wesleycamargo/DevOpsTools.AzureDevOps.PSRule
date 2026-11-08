function Get-AzDevOpsPermissionEvidence {
    <#
    .SYNOPSIS
    Collect direct ACL evidence for one security namespace and exact resource token.
    .DESCRIPTION
    An empty ACL response is complete only when the Azure DevOps API confirms a complete
    response for the requested token. This evaluator intentionally does not resolve
    inherited or effective permissions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$NamespaceId,
        [Parameter(Mandatory)][string]$Token
    )
    if ($null -eq $script:connection) { throw 'Not connected to Azure DevOps. Run Connect-AzDevOps first.' }
    $evidence = [ordered]@{
        SchemaVersion = 1; Status = 'Partial'; NamespaceId = $NamespaceId.ToString(); Token = $Token
        ScopeComplete = $false; Acls = @(); CollectedAt = [DateTime]::UtcNow.ToString('o'); ReasonCode = 'CollectionIncomplete'
    }
    $organization = $script:connection.Organization
    $header = $script:connection.GetHeader()
    try {
        $namespaceResponse = Invoke-RestMethod -Uri "https://dev.azure.com/$organization/_apis/securitynamespaces/$($NamespaceId)?api-version=7.1" -Headers $header -Method Get -ErrorAction Stop
        $namespaces = @($namespaceResponse.value | Where-Object namespaceId -EQ $NamespaceId.ToString())
        if ($namespaces.Count -ne 1) { throw 'NamespaceUnavailable' }

        $encoded = [Uri]::EscapeDataString($Token)
        $response = Invoke-RestMethod -Uri "https://dev.azure.com/$organization/_apis/accesscontrollists/$($NamespaceId)?token=$encoded&includeExtendedInfo=true&recurse=false&api-version=7.1" -Headers $header -Method Get -ErrorAction Stop
        if ($null -eq $response.value -or $null -eq $response.count -or $response.count -ne @($response.value).Count) { throw 'AclResponseIncomplete' }
        $matches = @($response.value | Where-Object token -EQ $Token)
        if ($matches.Count -gt 1 -or ($response.count -gt 0 -and $matches.Count -ne 1)) { throw 'AclResponseIncomplete' }
        $acl = if ($matches.Count -eq 1) { $matches[0] } else {
            [pscustomobject]@{ token = $Token; inheritPermissions = $true; acesDictionary = [pscustomobject]@{} }
        }
        if ($null -eq $acl.acesDictionary) { throw 'AclResponseIncomplete' }
        $evidence.Acls = @($acl)
        $evidence.ScopeComplete = $true
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
