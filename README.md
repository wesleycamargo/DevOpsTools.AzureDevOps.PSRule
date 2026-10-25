# DevOpsTools.AzureDevOps.PSRule

[![PowerShell Gallery Version (excluding pre-releases)](https://img.shields.io/powershellgallery/v/DevOpsTools.AzureDevOps.PSRule?logo=powershell&link=https%3A%2F%2Fwww.powershellgallery.com%2Fpackages%2FDevOpsTools.AzureDevOps.PSRule)](https://www.powershellgallery.com/packages/DevOpsTools.AzureDevOps.PSRule)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/DevOpsTools.AzureDevOps.PSRule?logo=powershell&link=https%3A%2F%2Fwww.powershellgallery.com%2Fpackages%2FDevOpsTools.AzureDevOps.PSRule)](https://www.powershellgallery.com/packages/DevOpsTools.AzureDevOps.PSRule)
[![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/module-ci.yml?label=Pester%20Unit%20Tests)](https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/actions/workflows/module-ci.yml)
[![codecov](https://codecov.io/gh/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/graph/badge.svg)](https://codecov.io/gh/wesleycamargo/DevOpsTools.AzureDevOps.PSRule)

## PSRule Module for Azure DevOps

This powershell module is built to be used with
[Bernie White's](https://github.com/BernieWhite) excellent
[PSRule](https://github.com/microsoft/PSRule) module to check
an Azure DevOps project for best practices for a
secure development environment. The module takes best practices from the official
[Azure DevOps Security best practices](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops) documentation. It can
function as a periodic security scan and check for your Azure DevOps project.

This module is actively developed since August 2023. Although a lot of testing has been
performed and is built in to the development cycle, up to now little feedback has come
back from the community yet. Any input on the direction of the module and included rules
is very much appreciated. Please consider opening an
[issue](https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/issues)
with your ideas, encountered problems in using the module or other contributions. Any
feedback is highly appreciated.

![Screenshot of version 0.0.11 Sarif output in Azure DevOps](assets/media/sarif-0.0.11.png)

### Easy to use spin-off project

If you are looking for an easy to use spin-off project that uses this module and
gives you a nice dashboard in Azure Monitor, please have a look at the
[PsrAzDo-workbooks](https://github.com/cloudyspells/PsrAzDo-workbooks) project.
It is a set of Azure Monitor Workbooks that can be used to visualize the results
of the DevOpsTools.AzureDevOps.PSRule module. The workbooks are easily deployed through
through the included Bicep template and modules. A Yaml pipeline is included to
run the DevOpsTools.AzureDevOps.PSRule module on a daily basis and upload the results
to Azure Monitor.

## Usage

### Migration to the new module name

`DevOpsTools.AzureDevOps.PSRule` starts at version **0.2.0**, with module GUID
`f77fbd3d-03be-4e42-98f3-4c185cc93bba`. It replaces
[`DevOpsTools.AzureDevOps.Assessment` 0.1.0](https://www.powershellgallery.com/packages/DevOpsTools.AzureDevOps.Assessment/0.1.0).
Development now lives in the renamed private repository
`wesleycamargo/DevOpsTools.AzureDevOps.PSRule`, preserving the Git commit
history of [the predecessor repository](https://github.com/wesleycamargo/PSRule.Rules.AzureDevOps).
The 2026-10-25 migration preserves the GPLv3 license and original author credits.
The existing `v0.1.0` tag and published Assessment package remain historical
releases. The rename does not reset assessment policy or report schema versions.

Install the new package separately once published; updating the old package does
not migrate it. Update imports, PSRule `-Module` selections, and dependencies
that specify a module name, version, or GUID. Commands, parameters, rule IDs,
baselines, and assessment data formats remain unchanged. There is no compatibility
package under the old name. Use a fresh PowerShell session for the migration
because both packages export the same commands.

See [repository architecture](docs/architecture.md) for module boundaries, data contracts,
pipeline structure, and architecture decision records.

Use [assessment collection completeness](docs/assessment-completeness.md) to check
collection coverage before evaluating rules, including strict exports and separate
JSON completeness reports.

For the companion three-tab pipeline dashboard, see
[Project Health & Compliance](docs/project-health.md). That guide identifies the
report-producing pipeline, explains measured remediation priority when effort is
unset, and links the validated report and dashboard implementation. The module's
weekly assessment pipeline remains a separate completeness/SARIF workflow.

To use this module, you need to have _PSRule_ installed.
You can install it from the PowerShell Gallery:

```powershell
Install-Module -Name PSRule -Scope CurrentUser
```

Once you have PSRule installed, you can install this module
from the PowerShell Gallery:

```powershell
Install-Module -Name DevOpsTools.AzureDevOps.PSRule -Scope CurrentUser
```

For the version published from this repository, use the [GitHub release installation instructions](docs/releases.md).

### PAT Token

Once you have both modules installed, you can connect to your
Azure DevOps organization and run an export of your Azure DevOps
project and run the rules on the exported data.
The `-PAT` value needs to be an Azure DevOps Personal Access Token
with sufficient permissions to read the project data. The default
expects a PAT with full access permissions. Alternately, you can
use a PAT with only read permissions or fine-grained permissions
with the `-TokenType` parameter. The fine-grained permissions expect
read access to all scopes and read & manage for scope that do not
have read-only access. Documentation on how to create the PATs can
be found in the [docs/token-permissions.md](docs/token-permissions.md).

#### Example: Run with full access token

```powershell
$connectParams = @{
    Organization = "MyOrg"
    PAT          = $MyPAT
}
Connect-AzDevOps @connectParams

$exportParams = @{
    Project    = "MyProject"
    OutputPath = "C:\Temp\MyProject"
}
Export-AzDevOpsRuleData @exportParams

$assertParams = @{
    InputPath = "C:\Temp\MyProject\"
    Module    = "DevOpsTools.AzureDevOps.PSRule"
}
Assert-PSRule @assertParams
```

#### Example: Run with read-only access token

```powershell
$connectParams = @{
    Organization = "MyOrg"
    PAT          = $MyPAT
    TokenType    = "ReadOnly"
}
Connect-AzDevOps @connectParams

$exportParams = @{
    Project    = "MyProject"
    OutputPath = "C:\Temp\MyProject"
}
Export-AzDevOpsRuleData @exportParams

$assertParams = @{
    InputPath = "C:\Temp\MyProject\"
    Module    = "DevOpsTools.AzureDevOps.PSRule"
}
Assert-PSRule @assertParams
```

### Bearer Token

You can connect to your Azure DevOps organization using a Bearer token and 
run an export of your Azure DevOps project to evaluate the rules on the exported data. 
The -BearerToken value should be a valid Azure DevOps Bearer token with 
sufficient permissions to read the Organization data. By default, the token 
is expected to have full access permissions. Documentation on how to 
generate a Bearer token can be found in the official Azure DevOps documentation.

#### Example: Run with full access token

```powershell
$connectParams = @{
    Organization = "MyOrg"
    BearerToken  = $AccessToken
}
Connect-AzDevOps @connectParams

$exportParams = @{
    Project    = "MyProject"
    OutputPath = "C:\Temp\MyProject"
}
Export-AzDevOpsRuleData @exportParams

$assertParams = @{
    InputPath = "C:\Temp\MyProject\"
    Module    = "DevOpsTools.AzureDevOps.PSRule"
}
Assert-PSRule @assertParams
```

### Service Principal or Managed Identity

Since version 0.3.0 of the predecessor package, `PSRule.Rules.AzureDevOps`, you can also connect to your
Azure DevOps organization with a Service Principal or Managed Identity.
The `-AuthType` parameter can be set to `ServicePrincipal` or `ManagedIdentity`.
The Service Principal needs to have sufficient permissions to read the
project data. The default expects a Service Principal with project
administrator permissions. Alternately, you can use a Service Principal
with only read permissions or fine-grained permissions with the `-TokenType`
parameter.

#### Example: Run with a Service Principal

```powershell
$connectParams = @{
    Organization  = "MyOrg"
    AuthType      = "ServicePrincipal"
    ClientId      = $MyAppId
    ClientSecret  = $MyAppSecret
    TenantId      = $MyTenantId
}
Connect-AzDevOps @connectParams

$exportParams = @{
    Project    = "MyProject"
    OutputPath = "C:\Temp\MyProject"
}
Export-AzDevOpsRuleData @exportParams

$assertParams = @{
    InputPath = "C:\Temp\MyProject\"
    Module    = "DevOpsTools.AzureDevOps.PSRule"
}
Assert-PSRule @assertParams
```

#### Example: Run with a System Assigned Managed Identity

```powershell
$connectParams = @{
    Organization = "MyOrg"
    AuthType     = "ManagedIdentity"
}
Connect-AzDevOps @connectParams

$exportParams = @{
    Project    = "MyProject"
    OutputPath = "C:\Temp\MyProject"
}
Export-AzDevOpsRuleData @exportParams

$assertParams = @{
    InputPath = "C:\Temp\MyProject\"
    Module    = "DevOpsTools.AzureDevOps.PSRule"
}
Assert-PSRule @assertParams
```

#### Example: Run with a User Assigned Managed Identity

```powershell
$env:ADO_MSI_CLIENT_ID = $MyClientId

$connectParams = @{
    Organization = "MyOrg"
    AuthType     = "ManagedIdentity"
}
Connect-AzDevOps @connectParams

$exportParams = @{
    Project    = "MyProject"
    OutputPath = "C:\Temp\MyProject"
}
Export-AzDevOpsRuleData @exportParams

$assertParams = @{
    InputPath = "C:\Temp\MyProject\"
    Module    = "DevOpsTools.AzureDevOps.PSRule"
}
Assert-PSRule @assertParams
```

![Screenshot of version 0.0.9 run](assets/media/run-0.0.9.png)

### Organization level export

Since version 0.0.8 of the predecessor package, `PSRule.Rules.AzureDevOps`, you can also export the
data at the organization level, looping through all projects
in the organization the PAT has access to.

```powershell
$exportOrgParams = @{
    Organization   = "MyOrg"
    OrganizationId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    OutputPath     = "C:\Temp\MyOrg"
}
Export-AzDevOpsOrganizationRuleData @exportOrgParams
```

### Disable checks for Azure DevOps Features that require additional licenses

Since version 0.0.12 of the predecessor package, `PSRule.Rules.AzureDevOps`, you can disable rules that
check for Azure DevOps features that require additional licenses.
This is done through applying the `Baseline.NoExtraLicense`
baseline to the `Assert-PSRule` command through the `-Baseline`
option.

```powershell
$assertParams = @{
    InputPath = "C:\Temp\MyProject\"
    Module    = "DevOpsTools.AzureDevOps.PSRule"
    Baseline  = "Baseline.NoExtraLicense"
}
Assert-PSRule @assertParams
```

## Rules

Documentation for the implemented rules can be found in the
[en](src/DevOpsTools.AzureDevOps.PSRule/en/) folder in the module folder.

This [annotated version of the official security best practices](docs/security-best-practices.md)
provides a reference for how the rules in this module are related to the
best practices recommended by Microsoft. It is the main guiding document
in building the ruleset for this module.

### Implemented rules

- [Azure.DevOps.Groups.ProjectAdmins.MaxMembers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Groups.ProjectAdmins.MaxMembers.md)
- [Azure.DevOps.Groups.ProjectAdmins.MinMembers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Groups.ProjectAdmins.MinMembers.md)
- [Azure.DevOps.Groups.ProjectValidUsers.DoNotAssignMemberOfOtherGroups](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Groups.ProjectValidUsers.DoNotAssignMemberOfOtherGroups.md)
- [Azure.DevOps.Pipelines.Core.InheritedPermissions](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Core.InheritedPermissions.md)
- [Azure.DevOps.Pipelines.Core.NoPlainTextSecrets](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Core.NoPlainTextSecrets.md)
- [Azure.DevOps.Pipelines.Core.ProjectValidUsers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Core.ProjectValidUsers.md)
- [Azure.DevOps.Pipelines.Core.UseYamlDefinition](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Core.UseYamlDefinition.md)
- [Azure.DevOps.Pipelines.Environments.Description](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Environments.Description.md)
- [Azure.DevOps.Pipelines.Environments.InheritedPermissions](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Environments.InheritedPermissions.md)
- [Azure.DevOps.Pipelines.Environments.ProductionBranchLimit](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Environments.ProductionBranchLimit.md)
- [Azure.DevOps.Pipelines.Environments.ProductionCheckProtection](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Environments.ProductionCheckProtection.md)
- [Azure.DevOps.Pipelines.Environments.ProductionHumanApproval](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Environments.ProductionHumanApproval.md)
- [Azure.DevOps.Pipelines.Environments.ProjectValidUsers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Environments.ProjectValidUsers.md)
- [Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest.md)
- [Azure.DevOps.Pipelines.PipelineYaml.StepDisplayName](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.PipelineYaml.StepDisplayName.md)
- [Azure.DevOps.Pipelines.Releases.Definition.InheritedPermissions](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Releases.Definition.InheritedPermissions.md)
- [Azure.DevOps.Pipelines.Releases.Definition.NoPlainTextSecrets](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Releases.Definition.NoPlainTextSecrets.md)
- [Azure.DevOps.Pipelines.Releases.Definition.ProductionApproval](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Releases.Definition.ProductionApproval.md)
- [Azure.DevOps.Pipelines.Releases.Definition.ProjectValidUsers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Releases.Definition.ProjectValidUsers.md)
- [Azure.DevOps.Pipelines.Releases.Definition.SelfApproval](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Releases.Definition.SelfApproval.md)
- [Azure.DevOps.Pipelines.Settings.LimitJobAuthorizationScope](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Settings.LimitJobAuthorizationScope.md)
- [Azure.DevOps.Pipelines.Settings.LimitJobAuthorizationScopeForReleasePipelines](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Settings.LimitJobAuthorizationScopeForReleasePipelines.md)
- [Azure.DevOps.Pipelines.Settings.LimitJobAuthorizationScopeForYamlPipelines](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Settings.LimitJobAuthorizationScopeForYamlPipelines.md)
- [Azure.DevOps.Pipelines.Settings.LimitSetVariablesAtQueueTime](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Settings.LimitSetVariablesAtQueueTime.md)
- [Azure.DevOps.Pipelines.Settings.RequireCommentForPullRequestFromFork](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Settings.RequireCommentForPullRequestFromFork.md)
- [Azure.DevOps.Pipelines.Settings.RestrictSecretsForPullRequestFromFork](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Settings.RestrictSecretsForPullRequestFromFork.md)
- [Azure.DevOps.Pipelines.Settings.SanitizeShellTaskArguments](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Settings.SanitizeShellTaskArguments.md)
- [Azure.DevOps.Pipelines.Settings.StatusBadgesPrivate](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Pipelines.Settings.StatusBadgesPrivate.md)
- [Azure.DevOps.Project.MainEnvironmentAcl.ProjectValidUsers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Project.MainEnvironmentAcl.ProjectValidUsers.md)
- [Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Project.MainPipelineAcl.ProjectValidUsers.md)
- [Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Project.MainReleaseDefinitionAcl.ProjectValidUsers.md)
- [Azure.DevOps.Project.MainRepositoryAcl.ProjectValidUsers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Project.MainRepositoryAcl.ProjectValidUsers.md)
- [Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Project.MainServiceConnectionAcl.ProjectValidUsers.md)
- [Azure.DevOps.Project.MainVariableGroupAcl.ProjectValidUsers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Project.MainVariableGroupAcl.ProjectValidUsers.md)
- [Azure.DevOps.Project.Visibility](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Project.Visibility.md)
- [Azure.DevOps.Repos.Branch.BranchPolicyAllowSelfApproval](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.Branch.BranchPolicyAllowSelfApproval.md)
- [Azure.DevOps.Repos.Branch.BranchPolicyCommentResolution](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.Branch.BranchPolicyCommentResolution.md)
- [Azure.DevOps.Repos.Branch.BranchPolicyEnforceLinkedWorkItems](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.Branch.BranchPolicyEnforceLinkedWorkItems.md)
- [Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.Branch.BranchPolicyIsEnabled.md)
- [Azure.DevOps.Repos.Branch.BranchPolicyMergeStrategy](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.Branch.BranchPolicyMergeStrategy.md)
- [Azure.DevOps.Repos.Branch.BranchPolicyMinimumReviewers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.Branch.BranchPolicyMinimumReviewers.md)
- [Azure.DevOps.Repos.Branch.BranchPolicyRequireBuild](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.Branch.BranchPolicyRequireBuild.md)
- [Azure.DevOps.Repos.Branch.BranchPolicyResetVotes](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.Branch.BranchPolicyResetVotes.md)
- [Azure.DevOps.Repos.Branch.HasBranchPolicy](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.Branch.HasBranchPolicy.md)
- [Azure.DevOps.Repos.DefaultBranchPolicyAllowSelfApproval](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.DefaultBranchPolicyAllowSelfApproval.md)
- [Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.DefaultBranchPolicyCommentResolution.md)
- [Azure.DevOps.Repos.DefaultBranchPolicyEnforceLinkedWorkItems](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.DefaultBranchPolicyEnforceLinkedWorkItems.md)
- [Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.DefaultBranchPolicyIsEnabled.md)
- [Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.DefaultBranchPolicyMergeStrategy.md)
- [Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.DefaultBranchPolicyMinimumReviewers.md)
- [Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.DefaultBranchPolicyRequireBuild.md)
- [Azure.DevOps.Repos.DefaultBranchPolicyResetVotes](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.DefaultBranchPolicyResetVotes.md)
- [Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.GitHubAdvancedSecurityBlockPushes.md)
- [Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.GitHubAdvancedSecurityEnabled.md)
- [Azure.DevOps.Repos.HasDefaultBranchPolicy](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.HasDefaultBranchPolicy.md)
- [Azure.DevOps.Repos.InheritedPermissions](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.InheritedPermissions.md)
- [Azure.DevOps.Repos.License](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.License.md)
- [Azure.DevOps.Repos.ProjectValidUsers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.ProjectValidUsers.md)
- [Azure.DevOps.Repos.Readme](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Repos.Readme.md)
- [Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.RetentionSettings.ArtifactMinimumRetentionDays.md)
- [Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.RetentionSettings.PullRequestRunsMinimumRetentionDays.md)
- [Azure.DevOps.ServiceConnections.ClassicAzure](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.ServiceConnections.ClassicAzure.md)
- [Azure.DevOps.ServiceConnections.Description](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.ServiceConnections.Description.md)
- [Azure.DevOps.ServiceConnections.GitHubPAT](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.ServiceConnections.GitHubPAT.md)
- [Azure.DevOps.ServiceConnections.InheritedPermissions](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.ServiceConnections.InheritedPermissions.md)
- [Azure.DevOps.ServiceConnections.ProductionBranchLimit](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.ServiceConnections.ProductionBranchLimit.md)
- [Azure.DevOps.ServiceConnections.ProductionCheckProtection](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.ServiceConnections.ProductionCheckProtection.md)
- [Azure.DevOps.ServiceConnections.ProductionHumanApproval](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.ServiceConnections.ProductionHumanApproval.md)
- [Azure.DevOps.ServiceConnections.ProjectValidUsers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.ServiceConnections.ProjectValidUsers.md)
- [Azure.DevOps.ServiceConnections.Scope](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.ServiceConnections.Scope.md)
- [Azure.DevOps.ServiceConnections.WorkloadIdentityFederation](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.ServiceConnections.WorkloadIdentityFederation.md)
- [Azure.DevOps.Tasks.VariableGroup.Description](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Tasks.VariableGroup.Description.md)
- [Azure.DevOps.Tasks.VariableGroup.InheritedPermissions](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Tasks.VariableGroup.InheritedPermissions.md)
- [Azure.DevOps.Tasks.VariableGroup.NoKeyVaultNoSecrets](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Tasks.VariableGroup.NoKeyVaultNoSecrets.md)
- [Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Tasks.VariableGroup.NoPlainTextSecrets.md)
- [Azure.DevOps.Tasks.VariableGroup.ProjectValidUsers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Tasks.VariableGroup.ProjectValidUsers.md)

### Implemented Organization rules

- [Azure.DevOps.Organization.GeneralBillingSettings.SubscriptionActive](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.GeneralBillingSettings.SubscriptionActive.md)
- [Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured.md)
- [Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled.md)
- [Azure.DevOps.Organization.GeneralOverview.DescriptionSet](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.GeneralOverview.DescriptionSet.md)
- [Azure.DevOps.Organization.GeneralOverview.TimeZoneSet](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.GeneralOverview.TimeZoneSet.md)
- [Azure.DevOps.Organization.GeneralOverview.GeographySet](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.GeneralOverview.GeographySet.md)
- [Azure.DevOps.Organization.GeneralOverview.OwnerSet](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.GeneralOverview.OwnerSet.md)
- [Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess.md)
- [Azure.DevOps.Organization.Pipelines.Settings.LimitSettableVariables](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.LimitSettableVariables.md)
- [Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeNonRelease](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeNonRelease.md)
- [Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeRelease](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeRelease.md)
- [Azure.DevOps.Organization.Pipelines.Settings.ProtectRepoAccessInYaml](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.ProtectRepoAccessInYaml.md)
- [Azure.DevOps.Organization.Pipelines.Settings.DisableClassicBuildPipelines](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.DisableClassicBuildPipelines.md)
- [Azure.DevOps.Organization.Pipelines.Settings.DisableClassicReleasePipelines](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.DisableClassicReleasePipelines.md)
- [Azure.DevOps.Organization.Pipelines.Settings.LimitPRsFromForks](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.LimitPRsFromForks.md)
- [Azure.DevOps.Organization.Pipelines.Settings.DisableBuildsFromForks](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.DisableBuildsFromForks.md)
- [Azure.DevOps.Organization.Pipelines.Settings.SanitizeShellTaskArguments](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.SanitizeShellTaskArguments.md)
- [Azure.DevOps.Organization.Pipelines.Settings.DisableStageChooser](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.DisableStageChooser.md)
- [Azure.DevOps.Organization.Pipelines.Settings.DisableInBoxTasksVar](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.DisableInBoxTasksVar.md)
- [Azure.DevOps.Organization.Pipelines.Settings.DisableMarketplaceTasksVar](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.DisableMarketplaceTasksVar.md)
- [Azure.DevOps.Organization.Pipelines.Settings.DisableNode6TasksVar](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.DisableNode6TasksVar.md)
- [Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeForForks](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeForForks.md)
- [Azure.DevOps.Organization.Pipelines.Settings.DisableSecretsFromForks](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.DisableSecretsFromForks.md)
- [Azure.DevOps.Organization.Pipelines.Settings.DisableImpliedYAMLCiTrigger](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.DisableImpliedYAMLCiTrigger.md)
- [Azure.DevOps.Organization.Pipelines.Settings.EnableAuditSettableVar](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.EnableAuditSettableVar.md)
- [Azure.DevOps.Organization.Pipelines.Settings.EnableTaskLockdown](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.EnableTaskLockdown.md)
- [Azure.DevOps.Organization.Pipelines.Settings.RestrictPipelinePoliciesPermission](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.RestrictPipelinePoliciesPermission.md)
- [Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForPullRequest](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForPullRequest.md)
- [Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamMembers](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamMembers.md)
- [Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamAndNonContributors](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamAndNonContributors.md)
- [Azure.DevOps.Organization.Pipelines.Settings.EnableShellTasksArgsSanitizingAudit](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Pipelines.Settings.EnableShellTasksArgsSanitizingAudit.md)
- [Azure.DevOps.Organization.Security.Policies.DisallowSecureShell](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.DisallowSecureShell.md)
- [Azure.DevOps.Organization.Security.Policies.DisallowRequestAccessToken](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.DisallowRequestAccessToken.md)
- [Azure.DevOps.Organization.Security.Policies.DisallowTeamAdminsInvitations](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.DisallowTeamAdminsInvitations.md)
- [Azure.DevOps.Organization.Security.Policies.DisallowFeedbackCollection](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.DisallowFeedbackCollection.md)
- [Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess.md)
- [Azure.DevOps.Organization.Security.Policies.DisallowOAuthAuthentication](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.DisallowOAuthAuthentication.md)
- [Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents.md)
- [Azure.DevOps.Organization.Security.Policies.EnableArtifactsProtection](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.EnableArtifactsProtection.md)
- [Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess.md)
- [Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess](src/DevOpsTools.AzureDevOps.PSRule/en/Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess.md)

## Improvement backlog

See the [assessment tool improvement backlog](docs/assessment-backlog.md)
for proposed priorities, acceptance criteria, and validation steps.

## Contributing

This project welcomes contributions and suggestions. Please read
[CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute.

## License

This project is [licensed under the MIT License](LICENSE).

## Acknowledgements

- [Bernie White](https://github.com/BernieWhite) for creating
  [PSRule](https://microsoft.github.io/PSRule/V2).

## Maintainer

- [Roderick Bant](https://github.com/webtonize)

## References

- [PSRule](https://microsoft.github.io/PSRule/V2)
- [PsrAzDo-workbooks](https://github.com/cloudyspells/PsrAzDo-workbooks) - Azure Monitor Workbooks for DevOpsTools.AzureDevOps.PSRule
- [Auditing an Azure DevOps project configuration with PSRule](https://medium.com/@webtonize/auditing-an-azure-devops-project-configuration-with-psrule-73cf17753827)
- [Audit Azure DevOps configuration with Sarif scan reports from the pipeline](https://medium.com/@webtonize/audit-azure-devops-configuration-with-sarif-scan-reports-from-the-pipeline-4ced6fc47988)
- [Azure DevOps Security best practices](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops)
