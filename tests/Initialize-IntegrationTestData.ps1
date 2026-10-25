<#
    .SYNOPSIS
    Creates the Azure DevOps resources that the Integration tests expect.

    .DESCRIPTION
    Idempotently seeds the test project with the repositories, pipelines,
    environments, variable groups, service connections, and release definitions
    referenced by name in the Integration tests. All values are dummy data.
    Authenticates with the current Azure CLI login.

    .EXAMPLE
    ./tests/Initialize-IntegrationTestData.ps1 -Organization ai-experiments -Project PSRule.Rules.AzureDevOps.Tests
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Organization,

    [Parameter(Mandatory)]
    [string]$Project
)

$ErrorActionPreference = 'Stop'

$token = az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv
if (-not $token) { throw 'Run az login first.' }
$headers = @{ Authorization = "Bearer $token" }
$base = "https://dev.azure.com/$Organization"

function Invoke-Ado {
    param([string]$Method = 'Get', [string]$Uri, $Body)
    $params = @{ Method = $Method; Uri = $Uri; Headers = $headers; ContentType = 'application/json' }
    if ($null -ne $Body) { $params.Body = ($Body | ConvertTo-Json -Depth 20) }
    Invoke-RestMethod @params
}

$projectInfo = Invoke-Ado -Uri "$base/_apis/projects/$Project`?api-version=7.1"
$projectId = $projectInfo.id

# Project Valid Users is matched by the rules through its SID suffix -0-0-0-0-3.
$pvu = (Invoke-Ado -Uri "https://vssps.dev.azure.com/$Organization/_apis/identities?searchFilter=General&filterValue=[$Project]\Project Valid Users&api-version=7.1").value[0]
$projectAdmins = (Invoke-Ado -Uri "https://vssps.dev.azure.com/$Organization/_apis/identities?searchFilter=General&filterValue=[$Project]\Project Administrators&api-version=7.1").value[0]

function Set-Acl {
    # Sets inheritance and explicit entries for one security token.
    param([string]$Namespace, [string]$Token, [bool]$Inherit, [hashtable]$Allow = @{})
    $current = (Invoke-Ado -Uri "$base/_apis/accesscontrollists/$Namespace`?token=$Token&api-version=7.1").value | Where-Object token -eq $Token
    # Only inheritance and the presence of explicit entries matter to the rules.
    $isCurrent = $current -and $current.inheritPermissions -eq $Inherit -and @($Allow.Keys | Where-Object {
            -not $current.acesDictionary.$_
        }).Count -eq 0
    if ($isCurrent) { return }
    $aces = @{}
    foreach ($descriptor in $Allow.Keys) {
        $aces[$descriptor] = @{ descriptor = $descriptor; allow = $Allow[$descriptor]; deny = 0 }
    }
    $body = @{ value = @(@{ token = $Token; inheritPermissions = $Inherit; acesDictionary = $aces }) }
    Invoke-Ado -Method Post -Uri "$base/_apis/accesscontrollists/$Namespace`?api-version=7.1" -Body $body | Out-Null
}

#region Repositories

function Get-OrCreateRepo {
    param([string]$Name)
    $repo = (Invoke-Ado -Uri "$base/$Project/_apis/git/repositories?api-version=7.1").value | Where-Object name -eq $Name
    if (-not $repo) {
        Write-Host "Creating repository $Name"
        $repo = Invoke-Ado -Method Post -Uri "$base/$Project/_apis/git/repositories?api-version=7.1" -Body @{ name = $Name; project = @{ id = $projectId } }
    }
    $repo
}

function Initialize-RepoContent {
    # Pushes the initial commit to main only when the repository has no branches.
    param($Repo, [hashtable]$Files)
    $refs = (Invoke-Ado -Uri "$base/$Project/_apis/git/repositories/$($Repo.id)/refs?filter=heads/&api-version=7.1").value
    if ($refs) { return }
    Write-Host "Pushing initial content to $($Repo.name)"
    $changes = foreach ($path in $Files.Keys) {
        @{ changeType = 'add'; item = @{ path = "/$path" }; newContent = @{ content = $Files[$path]; contentType = 'rawtext' } }
    }
    $body = @{
        refUpdates = @(@{ name = 'refs/heads/main'; oldObjectId = '0000000000000000000000000000000000000000' })
        commits    = @(@{ comment = 'Add integration test data'; changes = @($changes) })
    }
    Invoke-Ado -Method Post -Uri "$base/$Project/_apis/git/repositories/$($Repo.id)/pushes?api-version=7.1" -Body $body | Out-Null
}

function Add-Branch {
    param($Repo, [string]$Name)
    $refs = (Invoke-Ado -Uri "$base/$Project/_apis/git/repositories/$($Repo.id)/refs?filter=heads/&api-version=7.1").value
    if ($refs.name -contains "refs/heads/$Name") { return }
    $main = $refs | Where-Object name -eq 'refs/heads/main'
    Write-Host "Creating branch $Name in $($Repo.name)"
    $body = @(@{ name = "refs/heads/$Name"; oldObjectId = '0000000000000000000000000000000000000000'; newObjectId = $main.objectId })
    Invoke-RestMethod -Method Post -Uri "$base/$Project/_apis/git/repositories/$($Repo.id)/refs?api-version=7.1" -Headers $headers -ContentType 'application/json' -Body (ConvertTo-Json -InputObject $body -Depth 5) | Out-Null
}

$pipelineYaml = @"
trigger: none
pr: none

pool:
  vmImage: ubuntu-latest

steps:
- script: echo "Integration test data. Not intended to run."
"@

$parametersYaml = @"
trigger: none
pr: none

parameters:
- name: requiredValue
  type: string

pool:
  vmImage: ubuntu-latest

steps:
- script: echo "`${{ parameters.requiredValue }}"
"@

$successRepo = Get-OrCreateRepo -Name 'repository-success'
Initialize-RepoContent -Repo $successRepo -Files @{
    'README.md'           = "# repository-success`n`nIntegration test data for DevOpsTools.AzureDevOps.Assessment.`n"
    'LICENSE'             = "MIT License`n`nDummy license file for integration test data.`n"
    'azure-pipelines.yml' = $pipelineYaml
    'parameters.yml'      = $parametersYaml
}

$failRepo = Get-OrCreateRepo -Name 'psrule-fail-project'
Initialize-RepoContent -Repo $failRepo -Files @{
    'azure-pipelines.yml' = $pipelineYaml
}
Add-Branch -Repo $failRepo -Name 'fail-branch'

#endregion Repositories

#region YAML pipelines

function Get-OrCreatePipeline {
    param([string]$Name, $Repo, [string]$Path)
    $pipeline = (Invoke-Ado -Uri "$base/$Project/_apis/pipelines?api-version=7.1").value | Where-Object name -eq $Name
    if (-not $pipeline) {
        Write-Host "Creating pipeline $Name"
        $body = @{
            name          = $Name
            folder        = '\'
            configuration = @{ type = 'yaml'; path = $Path; repository = @{ id = $Repo.id; name = $Repo.name; type = 'azureReposGit' } }
        }
        $pipeline = Invoke-Ado -Method Post -Uri "$base/$Project/_apis/pipelines?api-version=7.1" -Body $body
    }
    $pipeline
}

$successPipeline = Get-OrCreatePipeline -Name 'psrule-success-project' -Repo $successRepo -Path '/azure-pipelines.yml'
$failPipeline = Get-OrCreatePipeline -Name 'psrule-fail-project' -Repo $failRepo -Path '/azure-pipelines.yml'
Get-OrCreatePipeline -Name 'psrule-required-parameters' -Repo $successRepo -Path '/parameters.yml' | Out-Null

#endregion YAML pipelines

#region Classic pipeline

# Requires classic build pipeline creation to be enabled in the organization.
$classicName = 'psrule-fail-project-CI-gui'
$classic = (Invoke-Ado -Uri "$base/$Project/_apis/build/definitions?name=$classicName&api-version=7.1").value
if (-not $classic) {
    Write-Host "Creating classic pipeline $classicName"
    $queue = (Invoke-Ado -Uri "$base/$Project/_apis/distributedtask/queues?queueName=Azure%20Pipelines&api-version=7.1-preview.1").value[0]
    $body = @{
        name       = $classicName
        path       = '\'
        type       = 'build'
        queue      = @{ id = $queue.id }
        repository = @{ id = $failRepo.id; name = $failRepo.name; type = 'TfsGit'; url = $failRepo.remoteUrl; defaultBranch = 'refs/heads/main' }
        process    = @{
            type   = 1
            phases = @(@{ name = 'Agent job 1'; refName = 'Job_1'; condition = 'succeeded()'; target = @{ type = 1 }; jobAuthorizationScope = 'projectCollection'; steps = @() })
        }
        # Fake secret-like value for the NoPlainTextSecrets rule.
        variables  = @{ connectionString = @{ value = 'password=NotARealSecret;' } }
        triggers   = @()
        jobAuthorizationScope = 'projectCollection'
    }
    Invoke-Ado -Method Post -Uri "$base/$Project/_apis/build/definitions?api-version=7.1" -Body $body | Out-Null
}

#endregion Classic pipeline

#region Branch policies

$existingPolicies = (Invoke-Ado -Uri "$base/$Project/_apis/policy/configurations?api-version=7.1").value

function Set-BranchPolicy {
    param([string]$TypeId, [hashtable]$Settings)
    $scope = @(@{ repositoryId = $successRepo.id; refName = 'refs/heads/main'; matchKind = 'exact' })
    $existing = $existingPolicies | Where-Object { $_.type.id -eq $TypeId -and $_.settings.scope[0].repositoryId -eq $successRepo.id }
    if ($existing) { return }
    Write-Host "Adding policy $TypeId to repository-success/main"
    $Settings.scope = $scope
    $body = @{ isEnabled = $true; isBlocking = $true; type = @{ id = $TypeId }; settings = $Settings }
    Invoke-Ado -Method Post -Uri "$base/$Project/_apis/policy/configurations?api-version=7.1" -Body $body | Out-Null
}

# Minimum reviewers
Set-BranchPolicy -TypeId 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' -Settings @{ minimumApproverCount = 1; creatorVoteCounts = $false; allowDownvotes = $false; resetOnSourcePush = $true }
# Work item linking
Set-BranchPolicy -TypeId '40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e' -Settings @{}
# Comment requirements
Set-BranchPolicy -TypeId 'c6a1889d-b943-4856-b76f-9e46bb6b0df2' -Settings @{}
# Require a merge strategy
Set-BranchPolicy -TypeId 'fa4e907d-c16b-4a4c-9dfa-4916e5d171ab' -Settings @{ allowSquash = $true; allowNoFastForward = $false; allowRebase = $false; allowRebaseMerge = $false }
# Build validation
Set-BranchPolicy -TypeId '0609b952-1397-4640-95ec-e00a01b2c241' -Settings @{ buildDefinitionId = $successPipeline.id; queueOnSourceUpdateOnly = $true; manualQueueOnly = $false; displayName = 'psrule-success-project'; validDuration = 720 }

#endregion Branch policies

#region Repository and pipeline permissions

$gitNamespace = '2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87'
$buildNamespace = '33344d9c-fc72-4d6f-aba5-fa317101a7e9'

# Success objects do not inherit and keep administrators explicit.
Set-Acl -Namespace $gitNamespace -Token "repoV2/$projectId/$($successRepo.id)" -Inherit $false -Allow @{ $projectAdmins.descriptor = 16382 }
Set-Acl -Namespace $buildNamespace -Token "$projectId/$($successPipeline.id)" -Inherit $false -Allow @{ $projectAdmins.descriptor = 32767 }

# Fail objects inherit and grant Project Valid Users direct permissions.
Set-Acl -Namespace $gitNamespace -Token "repoV2/$projectId/$($failRepo.id)" -Inherit $true -Allow @{ $pvu.descriptor = 4 }
Set-Acl -Namespace $buildNamespace -Token "$projectId/$($failPipeline.id)" -Inherit $true -Allow @{ $pvu.descriptor = 3 }

# The project-level repository ACL grants Project Valid Users a custom permission.
# Entries are merged so existing project permissions are kept.
$projectAce = @{ token = "repoV2/$projectId"; merge = $true; accessControlEntries = @(@{ descriptor = $pvu.descriptor; allow = 6; deny = 0 }) }
Invoke-Ado -Method Post -Uri "$base/_apis/accesscontrolentries/$gitNamespace`?api-version=7.1" -Body $projectAce | Out-Null

#endregion Repository and pipeline permissions

#region Environments

$environmentNamespace = '83d4c2e6-e57d-4d6e-892b-b87222b7ad20'

function Get-OrCreateEnvironment {
    param([string]$Name, [string]$Description)
    $environment = (Invoke-Ado -Uri "$base/$Project/_apis/pipelines/environments?name=$Name&api-version=7.1").value | Where-Object name -eq $Name
    if (-not $environment) {
        Write-Host "Creating environment $Name"
        $environment = Invoke-Ado -Method Post -Uri "$base/$Project/_apis/pipelines/environments?api-version=7.1" -Body @{ name = $Name; description = $Description }
    }
    $environment
}

function Add-Check {
    # Adds an approval and a branch control check to a protected resource.
    param([string]$ResourceType, [string]$ResourceId, [string]$ResourceName)
    $existing = (Invoke-Ado -Uri "$base/$Project/_apis/pipelines/checks/configurations?resourceType=$ResourceType&resourceId=$ResourceId&`$expand=settings&api-version=7.1-preview.1").value
    $resource = @{ type = $ResourceType; id = $ResourceId; name = $ResourceName }
    if (-not ($existing | Where-Object { $_.type.name -eq 'Approval' })) {
        Write-Host "Adding approval check to $ResourceName"
        Invoke-Ado -Method Post -Uri "$base/$Project/_apis/pipelines/checks/configurations?api-version=7.1-preview.1" -Body @{
            type     = @{ id = '8C6F20A7-A545-4486-9777-F762FAFE0D4D'; name = 'Approval' }
            resource = $resource
            timeout  = 1440
            settings = @{
                approvers                 = @(@{ id = $projectAdmins.id })
                minRequiredApprovers      = 1
                requesterCannotBeApprover = $true
                instructions              = 'Integration test data.'
                executionOrder            = 1
            }
        } | Out-Null
    }
    if (-not ($existing | Where-Object { $_.settings.displayName -eq 'Branch control' })) {
        Write-Host "Adding branch control check to $ResourceName"
        Invoke-Ado -Method Post -Uri "$base/$Project/_apis/pipelines/checks/configurations?api-version=7.1-preview.1" -Body @{
            type     = @{ id = 'fe1de3ee-a436-41b4-bb20-f6eb4cb879a7'; name = 'Task Check' }
            resource = $resource
            timeout  = 1440
            settings = @{
                definitionRef = @{ id = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'; name = 'evaluatebranchProtection'; version = '0.0.1' }
                displayName   = 'Branch control'
                inputs        = @{ allowedBranches = 'refs/heads/main'; ensureProtectionOfBranch = 'true'; allowUnknownStatusBranch = 'false' }
                retryInterval = 5
            }
        } | Out-Null
    }
}

# Order matters: the tests read environments[0] as unprotected and environments[1] as protected.
$failEnvironment = Get-OrCreateEnvironment -Name 'production-fail' -Description ''
$successEnvironment = Get-OrCreateEnvironment -Name 'production-success' -Description 'Integration test environment with checks.'
Add-Check -ResourceType 'environment' -ResourceId $successEnvironment.id -ResourceName $successEnvironment.name

Set-Acl -Namespace $environmentNamespace -Token "Environments/$projectId/$($successEnvironment.id)" -Inherit $false -Allow @{ $projectAdmins.descriptor = 63 }
Set-Acl -Namespace $environmentNamespace -Token "Environments/$projectId/$($failEnvironment.id)" -Inherit $true -Allow @{ $pvu.descriptor = 3 }

#endregion Environments

#region Variable groups

$libraryNamespace = 'b7e84409-6553-448a-bbb2-af228e07cbeb'

function Get-OrCreateVariableGroup {
    param([string]$Name, [string]$Description, [hashtable]$Variables)
    $group = (Invoke-Ado -Uri "$base/$Project/_apis/distributedtask/variablegroups?groupName=$Name&api-version=7.1").value
    if (-not $group) {
        Write-Host "Creating variable group $Name"
        $group = Invoke-Ado -Method Post -Uri "$base/_apis/distributedtask/variablegroups?api-version=7.1" -Body @{
            name                           = $Name
            description                    = $Description
            type                           = 'Vsts'
            variables                      = $Variables
            variableGroupProjectReferences = @(@{ name = $Name; description = $Description; projectReference = @{ id = $projectId; name = $Project } })
        }
    }
    $group
}

$successGroup = Get-OrCreateVariableGroup -Name 'variable-group-success' -Description 'Integration test variable group.' -Variables @{
    environment = @{ value = 'test' }
}
# Fake secret-like values for the secret rules.
$failGroup = Get-OrCreateVariableGroup -Name 'failing-variable-group' -Description '' -Variables @{
    connectionString = @{ value = 'password=NotARealSecret;' }
    fakeSecret       = @{ value = 'not-a-real-secret'; isSecret = $true }
}

Set-Acl -Namespace $libraryNamespace -Token "Library/$projectId/VariableGroup/$($successGroup.id)" -Inherit $false -Allow @{ $projectAdmins.descriptor = 63 }
Set-Acl -Namespace $libraryNamespace -Token "Library/$projectId/VariableGroup/$($failGroup.id)" -Inherit $true -Allow @{ $pvu.descriptor = 3 }

#endregion Variable groups

#region Service connections

# All connections use dummy identifiers and credentials and are never verified.
$endpointNamespace = '49b48001-ca20-4adc-8111-5b60c903a50c'
$dummySubscriptionId = '00000000-0000-0000-0000-000000000001'
$dummyTenantId = '00000000-0000-0000-0000-000000000002'
$dummyClientId = '00000000-0000-0000-0000-000000000003'

function Get-OrCreateServiceConnection {
    param([string]$Name, [hashtable]$Definition)
    $endpoint = (Invoke-Ado -Uri "$base/$Project/_apis/serviceendpoint/endpoints?endpointNames=$Name&api-version=7.1").value
    if (-not $endpoint) {
        Write-Host "Creating service connection $Name"
        $Definition.name = $Name
        $Definition.isShared = $false
        $Definition.serviceEndpointProjectReferences = @(@{ name = $Name; description = $Definition.description; projectReference = @{ id = $projectId; name = $Project } })
        $endpoint = Invoke-Ado -Method Post -Uri "$base/_apis/serviceendpoint/endpoints?api-version=7.1" -Body $Definition
    }
    $endpoint
}

function New-AzureRmDefinition {
    param([string]$Description, [hashtable]$Authorization)
    @{
        type          = 'azurerm'
        url           = 'https://management.azure.com/'
        description   = $Description
        authorization = $Authorization
        data          = @{
            environment      = 'AzureCloud'
            scopeLevel       = 'Subscription'
            subscriptionId   = $dummySubscriptionId
            subscriptionName = 'psrule-integration-test'
            creationMode     = 'Manual'
        }
    }
}

# Order matters: the tests read endpoints[0] as unprotected and endpoints[1] as protected.
$failEndpoint = Get-OrCreateServiceConnection -Name 'azurerm-fail' -Definition (New-AzureRmDefinition -Description '' -Authorization @{
        scheme     = 'ServicePrincipal'
        parameters = @{ tenantid = $dummyTenantId; serviceprincipalid = $dummyClientId; authenticationType = 'spnKey'; serviceprincipalkey = 'not-a-real-secret' }
    })
$successEndpoint = Get-OrCreateServiceConnection -Name 'azurerm-success' -Definition (New-AzureRmDefinition -Description 'Integration test service connection.' -Authorization @{
        scheme     = 'WorkloadIdentityFederation'
        parameters = @{ tenantid = $dummyTenantId; serviceprincipalid = $dummyClientId }
    })

# Creating with a scope requests a role assignment, so the scope is added by update instead.
$successScope = "/subscriptions/$dummySubscriptionId/resourcegroups/psrule-integration-test"
$successEndpoint = Invoke-Ado -Uri "$base/$Project/_apis/serviceendpoint/endpoints/$($successEndpoint.id)?api-version=7.1"
if ($successEndpoint.authorization.parameters.scope -ne $successScope) {
    Write-Host 'Adding resource group scope to azurerm-success'
    $successEndpoint.authorization.parameters | Add-Member -NotePropertyName scope -NotePropertyValue $successScope -Force
    $successEndpoint = Invoke-Ado -Method Put -Uri "$base/_apis/serviceendpoint/endpoints/$($successEndpoint.id)?api-version=7.1" -Body $successEndpoint
}
$classicEndpoint = Get-OrCreateServiceConnection -Name 'Classic-azure-fail' -Definition @{
    type          = 'azure'
    url           = 'https://management.core.windows.net/'
    description   = ''
    authorization = @{ scheme = 'UsernamePassword'; parameters = @{ username = 'not-a-real-user'; password = 'not-a-real-secret' } }
    data          = @{ environment = 'AzureCloud'; subscriptionId = $dummySubscriptionId; subscriptionName = 'psrule-integration-test' }
}
$gitHubEndpoint = Get-OrCreateServiceConnection -Name 'GitHub-PAT-fail' -Definition @{
    type          = 'github'
    url           = 'https://github.com'
    description   = ''
    authorization = @{ scheme = 'Token'; parameters = @{ AccessToken = 'not-a-real-token' } }
}

Add-Check -ResourceType 'endpoint' -ResourceId $successEndpoint.id -ResourceName $successEndpoint.name

Set-Acl -Namespace $endpointNamespace -Token "endpoints/$projectId/$($successEndpoint.id)" -Inherit $false -Allow @{ $projectAdmins.descriptor = 31 }
foreach ($endpoint in @($failEndpoint, $classicEndpoint, $gitHubEndpoint)) {
    Set-Acl -Namespace $endpointNamespace -Token "endpoints/$projectId/$($endpoint.id)" -Inherit $true -Allow @{ $pvu.descriptor = 3 }
}

#endregion Service connections

#region Release definitions

# Requires classic release pipeline creation to be enabled in the organization.
$releaseNamespace = 'c788c23e-1b46-4162-8f5e-d7585343b5de'
$vsrm = "https://vsrm.dev.azure.com/$Organization/$Project/_apis/release/definitions"

function Get-OrCreateReleaseDefinition {
    param([string]$Name, [hashtable]$Variables, $Approvals)
    $definition = (Invoke-Ado -Uri "$vsrm`?searchText=$Name&isExactNameMatch=true&api-version=7.1").value
    if (-not $definition) {
        Write-Host "Creating release definition $Name"
        $queue = (Invoke-Ado -Uri "$base/$Project/_apis/distributedtask/queues?queueName=Azure%20Pipelines&api-version=7.1-preview.1").value[0]
        $definition = Invoke-Ado -Method Post -Uri "$vsrm`?api-version=7.1" -Body @{
            name              = $Name
            path              = '\'
            releaseNameFormat = 'Release-$(rev:r)'
            variables         = $Variables
            environments      = @(@{
                    name                = 'production'
                    rank                = 1
                    retentionPolicy     = @{ daysToKeep = 30; releasesToKeep = 3; retainBuild = $true }
                    preDeployApprovals  = @{
                        approvals       = @($Approvals)
                        approvalOptions = @{ releaseCreatorCanBeApprover = $false; executionOrder = 'beforeGates'; timeoutInMinutes = 0 }
                    }
                    postDeployApprovals = @{ approvals = @(@{ rank = 1; isAutomated = $true; isNotificationOn = $false }) }
                    deployPhases        = @(@{
                            rank            = 1
                            phaseType       = 'agentBasedDeployment'
                            name            = 'Agent job'
                            deploymentInput = @{ queueId = $queue.id; agentSpecification = @{ identifier = 'ubuntu-latest' } }
                            workflowTasks   = @()
                        })
                })
        }
    }
    $definition
}

$successRelease = Get-OrCreateReleaseDefinition -Name 'psrule-release-Success' -Variables @{ environment = @{ value = 'test' } } -Approvals @(
    @{ rank = 1; isAutomated = $false; isNotificationOn = $false; approver = @{ id = $projectAdmins.id } }
)
# Fake secret-like value for the NoPlainTextSecrets rule.
$failRelease = Get-OrCreateReleaseDefinition -Name 'psrule-release-Fail' -Variables @{ connectionString = @{ value = 'password=NotARealSecret;' } } -Approvals @(
    @{ rank = 1; isAutomated = $true; isNotificationOn = $false }
)

Set-Acl -Namespace $releaseNamespace -Token "$projectId/$($successRelease.id)" -Inherit $false -Allow @{ $projectAdmins.descriptor = 16383 }
Set-Acl -Namespace $releaseNamespace -Token "$projectId/$($failRelease.id)" -Inherit $true -Allow @{ $pvu.descriptor = 3 }

#endregion Release definitions

#region Project pipeline settings

# Fork options are only stored while builds from forks are enabled.
Invoke-Ado -Method Patch -Uri "$base/$Project/_apis/build/generalsettings?api-version=7.1-preview.1" -Body @{
    buildsEnabledForForks             = $true
    isCommentRequiredForPullRequest   = $true
    enforceNoAccessToSecretsFromForks = $true
} | Out-Null

#endregion Project pipeline settings

Write-Host 'Integration test data is ready.'
