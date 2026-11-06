. "$PSScriptRoot/../Assessment/ProjectValidUsersAssessment.ps1"
Set-Item Function:global:Get-AzDevOpsProjectValidUsersAcls -Value ${function:Get-AzDevOpsProjectValidUsersAcls}
Set-Item Function:global:Get-AzDevOpsProjectValidUsersAssessment -Value ${function:Get-AzDevOpsProjectValidUsersAssessment}
