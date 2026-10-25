. "$PSScriptRoot/../Assessment/SecretAssessment.ps1"
# PSRule runs helper functions in its own runspace and requires global scope.
Set-Item Function:global:Get-AzDevOpsVariableGroupSecretAssessment -Value ${function:Get-AzDevOpsVariableGroupSecretAssessment}
