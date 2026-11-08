# Run an Azure DevOps assessment pipeline from PowerShell Gallery

This guide shows how to run `DevOpsTools.AzureDevOps.PSRule` from PowerShell Gallery in Azure DevOps Pipelines. The example does not import the repository checkout, so a run always uses the explicitly pinned package version.

The example pins `DevOpsTools.AzureDevOps.PSRule` to `0.2.2`, which was the current Gallery release on November 8, 2026. Change `MODULE_VERSION` only after validating a newer published release. Keep an exact version so assessment results remain reproducible.

## Prerequisites

1. Create an **Azure Resource Manager service connection** backed by Microsoft Entra workload identity federation. Name it, for example, `my-azure-rm-connection`.
2. Add the service connection's Microsoft Entra identity to the Azure DevOps organization that hosts this pipeline, then grant it sufficient read access to that organization and every project being assessed. See [token permissions](token-permissions.md) for the REST areas collected by the module.
3. Authorize this pipeline to use the Azure Resource Manager service connection. The YAML supplies its name through a runtime parameter; it contains no client secret, tenant ID, PAT, or variable group.
4. Ensure the agent can reach `https://www.powershellgallery.com/`, Microsoft Entra ID, and `https://dev.azure.com/`. Microsoft-hosted agents include the Azure CLI; self-hosted agents need Azure CLI.

## Example pipeline

Save the following as `azure-pipelines.yml` in the repository that owns the assessment pipeline. Change only the default service-connection name before running it. The script derives the organization name from Azure Pipelines' `System.CollectionUri` predefined variable.

```yaml
trigger: none
pr: none

parameters:
  - name: azureResourceManagerServiceConnection
    displayName: Azure Resource Manager service connection
    type: string
    default: my-azure-rm-connection

variables:
  - name: PSRULE_VERSION
    value: "2.9.0"
  - name: MODULE_VERSION
    value: "0.2.2"

pool:
  vmImage: ubuntu-latest

steps:
  # This pipeline uses the published module, not files from this repository.
  - checkout: none

  - task: PowerShell@2
    displayName: Install pinned assessment modules
    inputs:
      targetType: inline
      pwsh: true
      script: |
        $ErrorActionPreference = 'Stop'
        $requiredModules = @(
            @{ Name = 'PSRule'; Version = [version]$env:PSRULE_VERSION }
            @{ Name = 'DevOpsTools.AzureDevOps.PSRule'; Version = [version]$env:MODULE_VERSION }
        )

        foreach ($requiredModule in $requiredModules) {
            $installedModule = Get-Module -ListAvailable -Name $requiredModule.Name |
                Where-Object { $_.Version -eq $requiredModule.Version } |
                Select-Object -First 1

            if ($null -eq $installedModule) {
                Install-Module -Name $requiredModule.Name `
                    -RequiredVersion $requiredModule.Version `
                    -Repository PSGallery `
                    -Scope CurrentUser `
                    -Force `
                    -SkipPublisherCheck
            }
        }
    env:
      PSRULE_VERSION: $(PSRULE_VERSION)
      MODULE_VERSION: $(MODULE_VERSION)

  - task: AzureCLI@3
    displayName: Export and assess Azure DevOps organization
    continueOnError: true
    inputs:
      connectionType: azureRM
      azureSubscription: ${{ parameters.azureResourceManagerServiceConnection }}
      scriptType: pscore
      scriptLocation: inlineScript
      inlineScript: |
        $ErrorActionPreference = 'Stop'
        $exportPath = Join-Path $env:AGENT_TEMPDIRECTORY ('psrule-export-' + [guid]::NewGuid().ToString())
        $reportPath = Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'psrule-results.sarif'
        $completenessPath = Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY 'collection-status.json'

        New-Item -Path $exportPath -ItemType Directory -Force | Out-Null
        New-Item -Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY -ItemType Directory -Force | Out-Null

        Import-Module -Name DevOpsTools.AzureDevOps.PSRule `
            -RequiredVersion $env:MODULE_VERSION `
            -Force

        $collectionUri = [uri]$env:SYSTEM_COLLECTIONURI
        if ($collectionUri.Host -ne 'dev.azure.com' -or $collectionUri.Segments.Count -lt 2) {
            throw "System.CollectionUri must be a dev.azure.com organization URI; received '$collectionUri'."
        }
        $organization = $collectionUri.Segments[1].Trim('/')
        if (-not $organization) {
            throw "System.CollectionUri did not contain an Azure DevOps organization name."
        }
        Write-Host "Assessing Azure DevOps organization '$organization' from System.CollectionUri."

        $accessToken = az account get-access-token `
            --resource 499b84ac-1321-427f-aa17-267ca6975798 `
            --query accessToken `
            --output tsv
        if (-not $accessToken) {
            throw 'AzureCLI@3 did not return an Azure DevOps access token from the service connection.'
        }

        $connectionData = Invoke-RestMethod `
            -Uri "$($collectionUri.AbsoluteUri)_apis/connectionData" `
            -Headers @{ Authorization = "Bearer $accessToken" }
        if (-not $connectionData.instanceId) {
            throw 'Azure DevOps did not return an organization identity.'
        }

        $organizationId = [guid]$connectionData.instanceId
        Connect-AzDevOps `
            -Organization $organization `
            -OrganizationId $organizationId `
            -AccessToken $accessToken

        Export-AzDevOpsOrganizationRuleData `
            -Organization $organization `
            -OrganizationId $organizationId `
            -OutputPath $exportPath `
            -CompletenessReportPath $completenessPath `
            -Strict

        $inputFiles = @(Get-ChildItem -LiteralPath $exportPath -File -Recurse -Filter '*.json' |
            Select-Object -ExpandProperty FullName)
        if ($inputFiles.Count -eq 0) {
            throw 'The organization export produced no JSON input files.'
        }

        Assert-PSRule `
            -InputPath $inputFiles `
            -Module DevOpsTools.AzureDevOps.PSRule `
            -Baseline Baseline.Default `
            -As Detail `
            -OutputPath $reportPath `
            -OutputFormat Sarif `
            -Outcome All
    env:
      SYSTEM_COLLECTIONURI: $(System.CollectionUri)
      MODULE_VERSION: $(MODULE_VERSION)

  - task: PublishPipelineArtifact@1
    displayName: Publish assessment reports
    condition: always()
    inputs:
      targetPath: $(Build.ArtifactStagingDirectory)
      artifact: psrule-results
```

## What the pipeline does

- Installs the exact PSRule and rules-module versions from `PSGallery`. It does not resolve an unpinned latest version.
- Imports the Gallery module by name and exact version.
- Uses `AzureCLI@3` with the named Azure Resource Manager service connection to obtain an Azure DevOps access token. No variable group or client secret is exposed to the script.
- Derives the Azure DevOps organization from `System.CollectionUri`, then derives the organization ID from Azure DevOps rather than hard-coding either value.
- Exports organization and project data to a new agent-temporary directory for every run.
- Writes `collection-status.json` outside the rule-input directory. `-Strict` attempts the configured collection and stops assessment if coverage is incomplete, while preserving that report.
- Evaluates only exported JSON files and writes a SARIF report.
- Publishes reports even when collection or evaluation fails. Because the assessment task uses `continueOnError: true`, Azure DevOps reports expected collection/rule failures as a partially successful pipeline rather than hiding the artifact.

The artifact contains `collection-status.json` and, when evaluation runs, `psrule-results.sarif`. It does not publish the exported Azure DevOps configuration data.

## Run and verify

1. Create the pipeline from the YAML file, select the authorized Azure Resource Manager service connection when queueing the run, and queue it manually.
2. In **Install pinned assessment modules**, verify that both modules resolve at the `PSRULE_VERSION` and `MODULE_VERSION` values shown in the run.
3. In **Export and assess Azure DevOps organization**, verify that `AzureCLI@3` authenticates through the service connection, the module import succeeds, and Azure DevOps returns an organization identity.
4. Confirm the organization in the log is the same organization encoded in `System.CollectionUri`; the example intentionally does not take an organization-name setting.
5. Download the `psrule-results` artifact. Confirm it contains `collection-status.json`; when collection is complete, confirm it also contains `psrule-results.sarif`.

If installation fails, validate the agent's access to PowerShell Gallery and confirm that the specified versions are published. If `AzureCLI@3` cannot obtain a token, validate the service-connection authorization and workload-identity configuration. If the collection-status report is `Partial` or `Unavailable`, correct the service connection identity's Azure DevOps permissions before treating missing rule results as compliance evidence. See [assessment collection completeness](assessment-completeness.md) for report statuses and reason codes.

## Upgrade policy

1. Review the release notes and Gallery package version.
2. Test the new version in a non-production pipeline with the same permissions and organization scope.
3. Change only `MODULE_VERSION` in the YAML after that test succeeds.
4. Retain the previous pipeline run and its artifact so results can be compared across the version change.

Do not replace `MODULE_VERSION` with an unpinned install. A moving dependency version makes it impossible to reproduce a historical assessment.
