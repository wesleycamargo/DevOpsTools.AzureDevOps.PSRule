# Check direct sensitive grants to Project Valid Users using namespace-specific policy.
# This is not a substitute for full effective permissions (nested groups, bypass, inherited ACL paths).
function Get-AzDevOpsProjectValidUsersAcls {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$TargetObject, [Parameter(Mandatory)][string]$RuleId)
    $groups = @{
        'Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers' = 'Pipelines'
        'Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers' = 'ServiceConnections'
        'Azure.DevOps.Project.MainRepositoryAcl.ProjectValidUsers' = 'Repositories'
        'Azure.DevOps.Project.MainEnvironmentAcl.ProjectValidUsers' = 'Environments'
        'Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers' = 'ReleaseDefinitions'
        'Azure.DevOps.Project.MainVariableGroupAcl.ProjectValidUsers' = 'VariableGroups'
    }
    if ($groups.ContainsKey($RuleId)) {
        $field = $groups[$RuleId]
        return $TargetObject.ProjectAcls.($field)
    }
    return $TargetObject.Acls
}

function Get-AzDevOpsProjectValidUsersAssessment {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$TargetObject, [Parameter(Mandatory)][string]$RuleId, [object]$Policy)

    $unknown = [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'BroadGroupPermissionEvidenceUnavailable' }
    if ($null -eq $Policy -or -not $Policy.Reference -or $null -eq $Policy.SensitiveMask) {
        return [pscustomobject]@{ Outcome = 'Unknown'; ReasonCode = 'BroadGroupPermissionPolicyUnavailable' }
    }
    [long]$sensitive = 0
    [long]$approved = 0
    if (-not [long]::TryParse([string]$Policy.SensitiveMask, [ref]$sensitive) -or $sensitive -le 0) {
        return $unknown
    }
    if ($null -ne $Policy.ApprovedMask -and (-not [long]::TryParse([string]$Policy.ApprovedMask, [ref]$approved) -or $approved -lt 0)) {
        return $unknown
    }
    $acls = @(Get-AzDevOpsProjectValidUsersAcls -TargetObject $TargetObject -RuleId $RuleId)
    if ($acls.Count -eq 0 -or ($acls.Count -eq 1 -and $null -eq $acls[0])) { return $unknown }
    $incomplete = $false
    $violations = 0
    foreach ($acl in $acls) {
        if ($null -eq $acl -or $null -eq $acl.acesDictionary) { $incomplete = $true; continue }
        $aces = if ($acl.acesDictionary -is [System.Collections.IDictionary]) {
            @($acl.acesDictionary.Values)
        } else {
            @($acl.acesDictionary.PSObject.Properties.Value)
        }
        foreach ($ace in $aces) {
            if ($null -eq $ace -or -not $ace.descriptor) { $incomplete = $true; continue }
            if ([string]$ace.descriptor -notmatch '-0-0-0-0-3$') { continue }
            [long]$allow = 0
            [long]$deny = 0
            if (-not [long]::TryParse([string]$ace.allow, [ref]$allow) -or
                -not [long]::TryParse([string]$ace.deny, [ref]$deny) -or
                $allow -lt 0 -or $deny -lt 0) {
                $incomplete = $true; continue
            }
            $unapproved = ($allow -band (-bnot $deny)) -band $sensitive -band (-bnot $approved)
            if ($unapproved -ne 0) { $violations++ }
        }
    }
    if ($violations -gt 0) {
        return [pscustomobject]@{ Outcome = 'Fail'; ReasonCode = 'UnauthorizedProjectValidUsersDirectGrant' }
    }
    if ($incomplete) { return $unknown }
    return [pscustomobject]@{ Outcome = 'Pass'; ReasonCode = 'ProjectValidUsersSensitiveDirectGrantsAuthorized' }
}
