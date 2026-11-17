function Get-AzDevOpsGitBranchSecurityTokens {
    param([guid]$ProjectId, [guid]$RepositoryId, [string]$Branch)

    if ($ProjectId -eq [guid]::Empty -or $RepositoryId -eq [guid]::Empty -or $Branch -cnotmatch '^refs/heads/[^/]+(/[^/]+)*$') {
        throw 'The default branch security token could not be determined.'
    }

    # Git refs are case-sensitive. Azure DevOps encodes each path component as UTF-16LE hex.
    $parts = @('repoV2', $ProjectId.ToString(), $RepositoryId.ToString(), 'refs', 'heads')
    foreach ($segment in $Branch.Substring('refs/heads/'.Length).Split('/')) {
        $parts += [BitConverter]::ToString([Text.Encoding]::Unicode.GetBytes($segment)).Replace('-', '').ToLowerInvariant()
    }
    for ($index = 0; $index -lt $parts.Count; $index++) {
        $token = $parts[0..$index] -join '/'
        if ($index -ge 3 -or $index -eq 0) { $token += '/' }
        $token
    }
}

function Get-AzDevOpsGitBranchBypassActions {
    $organization = $script:connection.Organization
    $namespaceId = $script:AzureDevOpsGitRepositoriesSecurityNamespaceId
    $uri = "https://dev.azure.com/$organization/_apis/securitynamespaces/$($namespaceId)?api-version=7.1"
    $response = Invoke-RestMethod -Uri $uri -Headers $script:connection.GetHeader() -Method Get -ErrorAction Stop
    $namespaces = @($response.value | Where-Object namespaceId -EQ $namespaceId.ToString())
    if ($namespaces.Count -ne 1) { throw 'Git security namespace unavailable.' }

    $actions = @{}
    foreach ($name in 'PolicyExempt', 'PullRequestBypassPolicy') {
        $matches = @($namespaces[0].actions | Where-Object name -EQ $name)
        if ($matches.Count -ne 1 -or [long]$matches[0].bit -le 0) { throw 'Git bypass permission unavailable.' }
        $actions[$name] = [long]$matches[0].bit
    }
    if (($actions.PolicyExempt -band $actions.PullRequestBypassPolicy) -ne 0) { throw 'Git bypass permission masks overlap.' }
    return $actions
}

function Get-AzDevOpsGitBranchGrants {
    param([string[]]$Tokens, [long]$BypassMask, [hashtable]$AclCache)

    $organization = $script:connection.Organization
    $namespaceId = $script:AzureDevOpsGitRepositoriesSecurityNamespaceId
    $headers = $script:connection.GetHeader()
    $grants = @{}
    foreach ($token in $Tokens) {
        if (-not $AclCache.ContainsKey($token)) {
            $encoded = [Uri]::EscapeDataString($token)
            $uri = "https://dev.azure.com/$organization/_apis/accesscontrollists/$($namespaceId)?token=$encoded&includeExtendedInfo=true&recurse=false&api-version=7.1"
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
            if ($null -eq $response.value -or $null -eq $response.count -or $response.count -ne @($response.value).Count -or $response.count -gt 1) {
                throw 'Git ACL response incomplete.'
            }
            $acl = $null
            if ($response.count -eq 1) {
                $acl = $response.value[0]
                if (-not $acl.token -or $acl.token.TrimEnd('/') -ne $token.TrimEnd('/') -or
                    $acl.inheritPermissions -isnot [bool] -or $null -eq $acl.acesDictionary) {
                    throw 'Git ACL scope unavailable.'
                }
            }
            $AclCache[$token] = $acl
        }
        $acl = $AclCache[$token]
        if ($null -eq $acl) { continue }
        if (-not $acl.inheritPermissions) { $grants.Clear() }
        foreach ($ace in $acl.acesDictionary.psobject.Properties.Value) {
            if (-not $ace.descriptor -or $null -eq $ace.allow -or $null -eq $ace.deny) {
                throw 'Git access control entry incomplete.'
            }
            $allow = [long]$ace.allow -band $BypassMask
            $deny = [long]$ace.deny -band $BypassMask
            $assigned = $allow -bor $deny
            if ($assigned -eq 0) { continue }
            $prior = $grants[$ace.descriptor]
            $grants[$ace.descriptor] = @{
                Allow = ([long]$prior.Allow -band (-bnot $assigned)) -bor $allow
                Deny = ([long]$prior.Deny -band (-bnot $assigned)) -bor $deny
            }
        }
    }
    return $grants
}

function ConvertTo-AzDevOpsGitIdentityDescriptor {
    param([object]$IdentityDescriptor)

    if ($IdentityDescriptor -is [string] -and $IdentityDescriptor) { return $IdentityDescriptor }
    if ($IdentityDescriptor.identityType -and $IdentityDescriptor.identifier) {
        return "$($IdentityDescriptor.identityType);$($IdentityDescriptor.identifier)"
    }
    throw 'Git ACL identity descriptor unavailable.'
}

function Get-AzDevOpsGitPermissionPrincipals {
    param([string]$Descriptor, [hashtable]$IdentityCache)

    $organization = $script:connection.Organization
    $headers = $script:connection.GetHeader()
    $remaining = [System.Collections.Generic.Queue[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $remaining.Enqueue($Descriptor)
    while ($remaining.Count -gt 0) {
        $current = $remaining.Dequeue()
        if (-not $seen.Add($current)) { continue }
        if (-not $IdentityCache.ContainsKey($current)) {
            $encoded = [Uri]::EscapeDataString($current)
            $uri = "https://vssps.dev.azure.com/$organization/_apis/identities?descriptors=$encoded&queryMembership=Direct&api-version=7.1"
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
            if ($response.count -ne 1 -or @($response.value).Count -ne 1) { throw 'Git ACL identity unavailable.' }
            $identity = $response.value[0]
            if ((ConvertTo-AzDevOpsGitIdentityDescriptor $identity.descriptor) -ne $current -or $identity.isContainer -isnot [bool]) {
                throw 'Git ACL identity response incomplete.'
            }
            if ($identity.isContainer -and ($null -eq $identity.members -or
                ($null -ne $identity.memberIds -and @($identity.memberIds).Count -ne @($identity.members).Count))) {
                throw 'Git ACL group membership incomplete.'
            }
            $IdentityCache[$current] = $identity
        }
        $identity = $IdentityCache[$current]
        if ($identity.isContainer) {
            foreach ($member in $identity.members) {
                $remaining.Enqueue((ConvertTo-AzDevOpsGitIdentityDescriptor $member))
            }
        } else {
            $current
        }
    }
}

function Get-AzDevOpsGitBranchBypassAssessment {
    param([object]$Repository, [hashtable]$Context, [object]$AllowedBypass)

    if (-not $Repository.defaultBranch) {
        return [pscustomobject]@{ Outcome = 'Unknown'; Reason = 'Default branch unavailable'; Grants = @() }
    }
    try {
        if (-not $Context.ContainsKey('Actions')) { $Context.Actions = Get-AzDevOpsGitBranchBypassActions }
        $actions = $Context.Actions
        $mask = $actions.PolicyExempt -bor $actions.PullRequestBypassPolicy
        $repoId = ($Repository.id | ConvertFrom-Json -ErrorAction Stop).originalId
        $tokens = @(Get-AzDevOpsGitBranchSecurityTokens -ProjectId $Repository.project.id -RepositoryId $repoId -Branch $Repository.defaultBranch)
        $grants = Get-AzDevOpsGitBranchGrants -Tokens $tokens -BypassMask $mask -AclCache $Context.Acls

        $authorized = @{}
        foreach ($entry in $AllowedBypass.psobject.Properties) {
            $entryMask = 0
            foreach ($name in $entry.Value) { $entryMask = $entryMask -bor $actions[$name] }
            foreach ($principal in Get-AzDevOpsGitPermissionPrincipals -Descriptor $entry.Name -IdentityCache $Context.Identities) {
                $authorized[$principal] = $authorized[$principal] -bor $entryMask
            }
        }
        $allows = @{}
        $denies = @{}
        foreach ($entry in $grants.GetEnumerator()) {
            foreach ($principal in Get-AzDevOpsGitPermissionPrincipals -Descriptor $entry.Key -IdentityCache $Context.Identities) {
                $allows[$principal] = $allows[$principal] -bor $entry.Value.Allow
                $denies[$principal] = $denies[$principal] -bor $entry.Value.Deny
            }
        }
        $effectiveGrants = @(foreach ($principal in ($allows.Keys | Sort-Object)) {
            $effective = [long]$allows[$principal] -band (-bnot [long]$denies[$principal])
            foreach ($name in 'PolicyExempt', 'PullRequestBypassPolicy') {
                if (($effective -band $actions[$name]) -ne 0) {
                    [pscustomobject]@{
                        Descriptor = $principal
                        Permission = $name
                        Authorized = ($authorized[$principal] -band $actions[$name]) -ne 0
                    }
                }
            }
        })
        if ($effectiveGrants.Authorized -contains $false) {
            return [pscustomobject]@{ Outcome = 'Fail'; Reason = 'Unauthorized bypass permission'; Grants = $effectiveGrants }
        }
        return [pscustomobject]@{ Outcome = 'Pass'; Reason = 'Bypass permissions are restricted to authorized identities'; Grants = $effectiveGrants }
    }
    catch {
        # API exceptions can include identity data or request details. Keep them out of the reports.
        return [pscustomobject]@{ Outcome = 'Unknown'; Reason = 'Git permissions or group membership unavailable'; Grants = @() }
    }
}
