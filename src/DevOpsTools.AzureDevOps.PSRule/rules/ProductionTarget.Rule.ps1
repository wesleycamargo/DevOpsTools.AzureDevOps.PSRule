. "$PSScriptRoot/../Assessment/ProductionTarget.ps1"
# PSRule evaluates selectors and preconditions in a separate runspace.
Set-Item Function:global:Test-AzDevOpsProductionName -Value ${function:Test-AzDevOpsProductionName}
Set-Item Function:global:Test-AzDevOpsProductionTarget -Value ${function:Test-AzDevOpsProductionTarget}
Set-Item Function:global:Get-AzDevOpsProductionReleaseEnvironments -Value ${function:Get-AzDevOpsProductionReleaseEnvironments}
Set-Item Function:global:Get-AzDevOpsProductionReleaseClassification -Value ${function:Get-AzDevOpsProductionReleaseClassification}
Set-Item Function:global:Get-AzDevOpsProductionBranchAssessment -Value ${function:Get-AzDevOpsProductionBranchAssessment}
