# Azure DevOps pipelines

The two operational entry points are:

| Pipeline | Source | Trigger |
| --- | --- | --- |
| Publish PSRule Module | `pipelines/azure-pipelines.yml` in this repository | Push to `main`, or manual on `main`. |
| run-assessment | `azure-pipelines/run-assessment.yml` in the companion dashboard repository | Daily 06:00 UTC and manual. |

## Module publishing

The Windows hosted job installs pinned PSRule/Pester dependencies, validates the
manifest, and runs `tests/Run-Tests.ps1 -TestType Unit`. Test results are retained
after failure. Successful validation permits Azure Artifacts publishing only on
`refs/heads/main`, never for PRs. The manifest version is published unchanged;
an existing version fails publication and requires a version bump.

Authorize the existing `devops-assessment-vg001` variable group containing:

- `azureDevOpsArtifactOrganizationName`
- `azureDevOpsArtifactProjectName`
- `azureDevOpsArtifactProjectNameFeedName`
- `azureDevOpsArtifactPatUser`
- `azureDevOpsArtifactPatToken` (secret)
- `psrule-rules-azuredevops-apikey` (secret)

The group and feed must exist before enabling the publisher. GitHub CI and
PSGallery publication remain separate workflows.

## Assessment

The companion pipeline uses `AI-Pool`, the `psrule-azure` service connection and
rule source from `main`. It performs strict collection and displays the dashboard
inside the pipeline without Azure workbook deployment or Log Analytics ingestion.
`psrule-results` contains collection status and generated SARIF/HTML/Markdown.
`AzureDevOpsRawData` separately retains original project JSON, including partial
exports when collection fails. Rule violations remain findings; incomplete
collection and execution failures fail the run.

The former weekly `psrule-assessment.yml` is retired. Disable its live definition
and old dashboard/deployment definitions after validating the replacement. Preserve
run history and the current Project Health reporter when migrating classic definition
17; see [Project Health integration](../docs/project-health.md).
