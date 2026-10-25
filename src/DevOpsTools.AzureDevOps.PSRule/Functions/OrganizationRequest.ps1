function Invoke-AzDevOpsOrganizationRequest {
    param ([string]$Uri, [hashtable]$Headers, [string]$Method = 'Get', [string]$Body)

    $parameters = @{ Uri = $Uri; Headers = $Headers; Method = $Method; UseBasicParsing = $true; ErrorAction = 'Stop' }
    if ($Body) { $parameters.Body = $Body }
    try {
        $response = Invoke-WebRequest @parameters
    }
    catch {
        $reason = 'RequestFailed'
        if ($_.Exception -is [Microsoft.PowerShell.Commands.HttpResponseException]) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            if ($statusCode -in 401, 403) { $reason = 'PermissionDenied' }
            elseif ($statusCode -in 404, 410, 429 -or $statusCode -ge 500) { $reason = 'EndpointUnavailable' }
        }
        Set-AzDevOpsCollectionStatus -Status Unavailable -ReasonCode $reason
        throw "Organization evidence request failed ($reason)."
    }
    if ($response.Content -match '<html|Sign In') {
        Set-AzDevOpsCollectionStatus -Status Unavailable -ReasonCode PermissionDenied
        throw 'Organization evidence request failed (PermissionDenied).'
    }
    try {
        return ConvertFrom-Json -InputObject $response.Content -ErrorAction Stop
    }
    catch {
        Set-AzDevOpsCollectionStatus -Status Unavailable -ReasonCode MalformedResponse
        throw 'Organization evidence response is not valid JSON (MalformedResponse).'
    }
}

function Test-AzDevOpsOrganizationDataType {
    param ($Data, [string[]]$BooleanProperties, [string[]]$StringProperties, [string[]]$AllowEmptyStringProperties)

    if ($null -eq $Data) { return }
    foreach ($property in $BooleanProperties + $StringProperties) {
        if ($null -eq $Data.$property) { continue }
        $valid = if ($property -in $BooleanProperties) { $Data.$property -is [bool] } else { $Data.$property -is [string] -and ($property -in $AllowEmptyStringProperties -or -not [string]::IsNullOrWhiteSpace($Data.$property)) }
        if (-not $valid) {
            $Data.$property = $null
            Set-AzDevOpsCollectionStatus -Status Partial -ReasonCode SchemaChanged
        }
    }
}
