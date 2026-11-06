# Verifies cloud-side RBAC evidence for the identity behind an Azure service connection.
# A DevOps scopeLevel alone is not sufficient to infer effective Azure permissions.
function Get-AzDevOpsServiceConnectionScopeAssessment {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$TargetObject, [object]$Policy)

    $unknown = [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'CloudRbacEvidenceUnavailable' }
    if ($null -eq $Policy -or -not $Policy.Reference -or $null -eq $Policy.ApprovedAssignments) {
        return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'CloudRbacPolicyUnavailable' }
    }
    $evidence = $TargetObject.CloudRbacEvidence
    if ($null -eq $evidence -or $evidence.Status -ne 'Complete' -or
        $evidence.InheritedAssignmentsIncluded -ne $true -or
        $evidence.RoleDefinitionsComplete -ne $true -or
        -not $evidence.Reference -or
        [string]$evidence.TargetName -cne [string]$TargetObject.ObjectName -or
        $null -eq $evidence.RoleAssignments) {
        return $unknown
    }
    $principal = $TargetObject.authorization.parameters.serviceprincipalid
    if ($principal -and [string]$evidence.PrincipalId -ine [string]$principal) {
        return $unknown
    }
    $allowed = @($Policy.ApprovedAssignments)
    foreach ($assignment in @($evidence.RoleAssignments)) {
        if (-not $assignment.Scope -or -not $assignment.RoleDefinitionId) { return $unknown }
        $scope = ([string]$assignment.Scope).TrimEnd('/')
        $role = [string]$assignment.RoleDefinitionId
        $approved = @($allowed | Where-Object {
            $_.Scope -and $_.RoleDefinitionId -and
            ([string]$_.Scope).TrimEnd('/') -ieq $scope -and
            [string]$_.RoleDefinitionId -ieq $role
        }).Count -gt 0
        if (-not $approved) {
            return [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'UnapprovedCloudRbacAssignment' }
        }
    }
    return [pscustomobject]@{ Outcome = 'Pass'; ReasonCode = 'CloudRbacAssignmentsApproved' }
}
