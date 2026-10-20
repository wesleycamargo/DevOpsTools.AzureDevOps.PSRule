function Invoke-AzDevOpsRestPage {
    param ([string]$Uri, [hashtable]$Headers)

    $responseHeaders = $null
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        $response = Invoke-WebRequest -Uri $Uri -Method Get -Headers $Headers -UseBasicParsing -ErrorAction Stop
        return [pscustomobject]@{ Body = ($response.Content | ConvertFrom-Json); Headers = $response.Headers }
    }
    $body = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Headers -ResponseHeadersVariable responseHeaders -ErrorAction Stop
    [pscustomobject]@{ Body = $body; Headers = $responseHeaders }
}

function Invoke-AzDevOpsPagedRequest {
    [CmdletBinding()]
    param ([string]$Uri, [hashtable]$Headers)

    $items = @()
    $requestUri = $Uri
    $seenTokens = @()
    do {
        $page = Invoke-AzDevOpsRestPage -Uri $requestUri -Headers $Headers
        $response = $page.Body
        $responseHeaders = $page.Headers
        if ($response -is [string]) { throw 'The collection endpoint returned an invalid response.' }
        Set-AzDevOpsMissingCollectionData -Data $response -RequiredProperties 'value'
        if ($null -eq $response -or 'value' -notin $response.PSObject.Properties.Name -or $null -eq $response.value) {
            throw 'The collection endpoint omitted its result list.'
        }
        $items += @($response.value)
        $continuationToken = if ($responseHeaders) { @($responseHeaders['x-ms-continuationtoken'])[0] } else { $null }
        if ($continuationToken) {
            if ($continuationToken -cin $seenTokens) { throw 'The collection endpoint repeated a continuation token.' }
            $seenTokens += $continuationToken
            $requestUri = $Uri + '&continuationToken=' + [uri]::EscapeDataString($continuationToken)
            $Headers = $script:connection.GetHeader()
        }
    } while ($continuationToken)
    [pscustomobject]@{ value = $items }
}
