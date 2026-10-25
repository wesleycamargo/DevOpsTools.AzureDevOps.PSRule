. "$PSScriptRoot/../Assessment/PolicyAssessment.ps1"
Set-Item Function:global:Get-AzDevOpsAssessmentField -Value ${function:Get-AzDevOpsAssessmentField}
Set-Item Function:global:Get-AzDevOpsAssessmentAgentImages -Value ${function:Get-AzDevOpsAssessmentAgentImages}
Set-Item Function:global:Get-AzDevOpsPolicyAssessment -Value ${function:Get-AzDevOpsPolicyAssessment}
