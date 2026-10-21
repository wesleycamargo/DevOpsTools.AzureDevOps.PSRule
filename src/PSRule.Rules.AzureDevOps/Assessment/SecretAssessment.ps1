# Shared evidence evaluation for the current control and its retained legacy alias.
function Get-AzDevOpsVariableGroupSecretAssessment {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$TargetObject)

    if ($null -eq $TargetObject.variables -or ($TargetObject.variables -isnot [System.Collections.IDictionary] -and $TargetObject.variables -isnot [pscustomobject])) {
        return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'VariablesUnavailable' }
    }
    $patterns = @(
        '((P|p)assword|pwd)\s*=\s*\w+;?'
        '(?# To match SQL/MySQL conn strings.)^Data Source=[^;]+;Initial Catalog=[^;]+;User ID=[^;]+;Password=[^;]+;$'
        '(?# To match SQL/MySQL conn strings.)((U|u)ser(Id)?|uid)\s*=\s*\w+;?'
        '(?# To match Azure storage keys.)^[A-Za-z0-9/+]{86}==$'
        '(?# To match Azure storage connection strings.)DefaultEndpointsProtocol=https;AccountName=\w+;AccountKey=[A-Za-z0-9/+]{86}==$'
        '(?# To match storage SAS.)([^?]*\?sv=)[^&]+(&s[a-z]=[^&]+){4}'
        '(?# To match Azure AD client secrets.)^[A-Za-z0-9-._~]{32}$'
        '(?# To match ADO PATs.)^[a-z2-7]{52}$'
        '(?# To match Azure Event Hub connection strings.)Endpoint=sb://[^/]+\.servicebus\.windows\.net/;SharedAccessKeyName=[^;]+;SharedAccessKey=[A-Za-z0-9+/=]{44}==$'
        '(?# To match Azure Service Bus connection strings.)Endpoint=sb://[^/]+\.servicebus\.windows\.net/;SharedAccessKeyName=[^;]+;SharedAccessKey=[A-Za-z0-9+/=]{44}==$'
        '(?# To match Azure Service Bus SAS.)((S|s)hared(A|a)ccess(S|s)ignature|sas)\s*=\s*\w+;?'
        '(?# To match Azure OpenAI API keys.)^sk-[a-zA-Z0-9]{32}$'
        '(?# To match Azure Cognitive Services API keys.)^[a-zA-Z0-9]{32}$'
        '(?# To match AWS access keys.)^AKIA[0-9A-Z]{16}$'
        '(?# To match AWS secret keys.)^[A-Za-z0-9/+=]{40}$'
        '(?# To match MongoDB connection strings.)mongodb://[^:]+:[^@]+@[^/]+/[^?]+(\?[^&]+(&[^&]+)*)?$'
        '(?# To match MongoDB SRV connection strings.)mongodb\+srv://[^:]+:[^@]+@[^/]+/[^?]+(\?[^&]+(&[^&]+)*)?$'
        '(?# To match Redis connection strings with password.)^redis://:[^@]+@[^:]+:\d+/?$'
        '(?# To match Redis SSL connection strings.)^rediss://[^:]+:[^@]+@[^:]+:\d+/?$'
        '(?# To match MySQL connection strings.)^Server=[^;]+;Port=\d+;Database=[^;]+;Uid=[^;]+;Pwd=[^;]+;$'
        '(?# To match PostgreSQL connection strings.)^Server=[^;]+;Port=\d+;Database=[^;]+;User Id=[^;]+;Password=[^;]+;$'
        '(?# To match PEM files.)^-----BEGIN [A-Z ]+-----\r?\n([A-Za-z0-9+/=]{64}\r?\n)*-----END [A-Z ]+-----\r?\n?$'
    )
    $variables = if ($TargetObject.variables -is [System.Collections.IDictionary]) {
        @($TargetObject.variables.Values)
    } else {
        @($TargetObject.variables.psobject.Properties.Value)
    }
    $incomplete = $false
    foreach ($variable in $variables) {
        if ($null -eq $variable) {
            $incomplete = $true
            continue
        }
        $fields = if ($variable -is [System.Collections.IDictionary]) { @($variable.Keys) } else { @($variable.psobject.Properties.Name) }
        # The collected value must be present, including an explicit null for masked secrets.
        if ('value' -notin $fields) {
            $incomplete = $true
            continue
        }
        if ($null -ne $variable.value) {
            if ($variable.isSecret -eq $true) {
                return [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'UnmaskedSecret' }
            }
            foreach ($pattern in $patterns) {
                if ([string]$variable.value -match $pattern) {
                    return [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'PlainTextCredential' }
                }
            }
        }
    }
    if ($incomplete) { return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'VariableEvidenceIncomplete' } }
    return [pscustomobject]@{ Outcome = 'Pass'; ReasonCode = 'NoExposedCredentialDetected' }
}
