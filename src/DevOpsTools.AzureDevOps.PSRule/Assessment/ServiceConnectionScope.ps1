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
        -not $evidence.Reference -or -not $evidence.PrincipalId -or
        ($evidence.IdentityVerified -isnot [bool] -or $evidence.IdentityVerified -ne $true) -or
        [string]$evidence.TargetName -cne [string]$TargetObject.ObjectName -or
        $null -eq $evidence.RoleAssignments) {
        return $unknown
    }
    $applicationId = [string]$TargetObject.authorization.parameters.serviceprincipalid
    $tenantId = [string]$TargetObject.authorization.parameters.tenantid
    $mapping = $evidence.IdentityMapping
    if ($null -eq $mapping -or $mapping.Verified -isnot [bool] -or
        $mapping.Verified -ne $true -or
        [string]::IsNullOrWhiteSpace([string]$mapping.Reference)) {
        return $unknown
    }
    foreach ($identity in @(
        $applicationId, $tenantId, [string]$evidence.PrincipalId,
        [string]$mapping.ApplicationId, [string]$mapping.PrincipalId, [string]$mapping.TenantId
    )) {
        $parsedIdentity = [guid]::Empty
        if (-not [guid]::TryParse($identity, [ref]$parsedIdentity) -or $parsedIdentity -eq [guid]::Empty) {
            return $unknown
        }
    }
    if ([string]$mapping.ApplicationId -ine $applicationId -or
        [string]$mapping.PrincipalId -ine [string]$evidence.PrincipalId -or
        [string]$mapping.TenantId -ine $tenantId) {
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
