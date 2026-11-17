# Private Microsoft Entra token acquisition for Connect-AzDevOps -Interactive.
function Get-AzDevOpsInteractiveToken {
    param ([string]$AuthProvider, [string]$TenantId, [switch]$AllowLogin)

    if ($AuthProvider -eq 'AzurePowerShell' -and -not (Get-Module Az.Accounts)) {
        try { Import-Module Az.Accounts -ErrorAction Stop }
        catch { throw 'Azure PowerShell authentication requires Az.Accounts. Install or repair it, or use -AuthProvider AzureCli.' }
    }

    $sessionToken = Request-AzDevOpsInteractiveToken -AuthProvider $AuthProvider -TenantId $TenantId
    if ($null -eq $sessionToken) {
        if (-not $AllowLogin) {
            Set-AzDevOpsCollectionStatus -Status Failed -ReasonCode AuthenticationRequired
            throw 'Your Azure session needs sign-in. Run Connect-AzDevOps -Interactive again.'
        }
        Invoke-AzDevOpsInteractiveLogin -AuthProvider $AuthProvider -TenantId $TenantId
        $sessionToken = Request-AzDevOpsInteractiveToken -AuthProvider $AuthProvider -TenantId $TenantId
        if ($null -eq $sessionToken) { throw "$AuthProvider still requires sign-in for Azure DevOps. Verify the Microsoft Entra account and tenant." }
    }
    return $sessionToken
}

function Request-AzDevOpsInteractiveToken {
    param ([string]$AuthProvider, [string]$TenantId)

    $resource = '499b84ac-1321-427f-aa17-267ca6975798'
    if ($AuthProvider -eq 'AzureCli') {
        $arguments = @('account', 'get-access-token', '--resource', $resource, '--output', 'json')
        if ($TenantId) { $arguments += @('--tenant', $TenantId) }
        $result = Invoke-AzDevOpsInteractiveAzureCli -Arguments $arguments
        if ($result.ExitCode -ne 0) {
            if (Test-AzDevOpsInteractiveLoginRequired -Details $result.Diagnostic) { return }
            throw 'Azure CLI could not obtain an Azure DevOps token. Verify the account and tenant, then retry.'
        }

        try {
            $response = ConvertFrom-Json -InputObject $result.Output -ErrorAction Stop
            if ($response.expires_on) {
                $expiresUtc = [DateTimeOffset]::FromUnixTimeSeconds([long]$response.expires_on).UtcDateTime
            }
            else {
                $expiresUtc = [DateTimeOffset]::Parse([string]$response.expiresOn, [cultureinfo]::InvariantCulture).UtcDateTime
            }
        }
        catch { throw 'Azure CLI returned an unreadable Azure DevOps token response. Update Azure CLI and retry.' }
        $accessToken = [string]$response.accessToken
        $accountTenant = [string]$response.tenant
    }
    else {
        $parameters = @{ ResourceUrl = $resource; ErrorAction = 'Stop' }
        if ($TenantId) { $parameters.TenantId = $TenantId }
        try {
            $response = Get-AzAccessToken @parameters
            $accessToken = if ($response.Token -is [securestring]) {
                [System.Net.NetworkCredential]::new('', $response.Token).Password
            }
            else { [string]$response.Token }
            $expiresUtc = ([DateTimeOffset]$response.ExpiresOn).UtcDateTime
            $accountTenant = [string]$response.TenantId
        }
        catch {
            if (Test-AzDevOpsInteractiveLoginRequired -Details $_.Exception.ToString()) { return }
            throw 'Azure PowerShell could not obtain an Azure DevOps token. Verify the account and tenant, then retry.'
        }
    }

    if ([string]::IsNullOrWhiteSpace($accessToken) -or $expiresUtc -le [datetime]::UtcNow) {
        throw "$AuthProvider returned a missing or expired Azure DevOps token. Sign in again and retry."
    }
    return [pscustomobject]@{
        AccessToken = $accessToken
        ExpiresUtc = $expiresUtc
        TenantId = if ($accountTenant) { $accountTenant } else { $TenantId }
    }
}

function Invoke-AzDevOpsInteractiveLogin {
    param ([string]$AuthProvider, [string]$TenantId)

    $cancelled = 'user[ _-]*cancel[l]?ed|cancel[l]?ed by (?:the )?user|keyboardinterrupt|operationcancel[l]?edexception'
    if ($AuthProvider -eq 'AzureCli') {
        $arguments = @('login', '--allow-no-subscriptions', '--output', 'none')
        if ($TenantId) { $arguments += @('--tenant', $TenantId) }
        $result = Invoke-AzDevOpsInteractiveAzureCli -Arguments $arguments -ShowLoginOutput
        if ($result.ExitCode -eq 130 -or $result.Diagnostic -match $cancelled) { throw 'Azure CLI sign-in was canceled.' }
        if ($result.ExitCode -ne 0) { throw 'Azure CLI sign-in failed. Verify the account and tenant, then retry.' }
    }
    else {
        $parameters = @{ SkipContextPopulation = $true; Scope = 'Process'; ErrorAction = 'Stop' }
        if ($TenantId) { $parameters.Tenant = $TenantId }
        try { Connect-AzAccount @parameters | Out-Null }
        catch {
            if ($_.Exception.ToString() -match $cancelled) { throw 'Azure PowerShell sign-in was canceled.' }
            throw 'Azure PowerShell sign-in failed. Verify the account and tenant, then retry.'
        }
    }
}

function Test-AzDevOpsInteractiveLoginRequired {
    param ([string]$Details)

    return $Details -match '(?:run|execute|using)\s+[''\"]?(?:az login|Connect-AzAccount)\b|interactive authentication is (?:needed|required)|\b(?:interaction_required|login_required|MsalUiRequiredException)\b|AADSTS(?:50058|50076|50079|50173|70043|700082)\b'
}

function Invoke-AzDevOpsInteractiveAzureCli {
    param ([string[]]$Arguments, [switch]$ShowLoginOutput)

    $az = Get-Command az -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $az) { throw 'Azure CLI is required for this authentication provider. Install Azure CLI or use -AuthProvider AzurePowerShell.' }

    # Capture native errors so they can be classified without printing token output.
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    $records = @(& $az.Source @Arguments 2>&1 | ForEach-Object {
        if ($ShowLoginOutput -and ($_ -is [string] -or [string]$_ -match '/devicelogin\b')) { Write-Host $_ }
        $_
    })
    $exitCode = $LASTEXITCODE

    return @{
        ExitCode = $exitCode
        Output = ($records | Where-Object { $_ -is [string] }) -join "`n"
        Diagnostic = if ($exitCode -ne 0) { $records -join "`n" }
    }
}
