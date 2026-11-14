Azure DevOps pipelines
======================

Module publication uses the GitHub Actions workflow
`.github/workflows/publish-on-release.yml` and PowerShell Gallery. The former
`azure-pipelines.yml` Azure Artifacts publisher has been retired. Existing feed
packages are unchanged; any live definition pointing to the retired YAML must
be disabled separately. See [module releases](../docs/releases.md) for validation,
packaging, and publication instructions.

`psrule-assessment.yml` is a separate, organization-wide PSRule assessment
pipeline. It runs manually or every Sunday at 02:00 UTC on `main`.

## Static project report

`psrule-assessment.yml` generates the module-owned `psrule-report.html` alongside
JSON and SARIF in the existing `psrule-results` artifact. Download it and open
`outputs/psrule-report.html` locally, or the corresponding retained timestamp
subdirectory when `KeepResults` is enabled. The HTML is project-only, with
embedded CSS and no JavaScript or network dependency when opened locally.
`PublishHtmlReport@1` also displays it under **Reports → Project assessment**;
the run UI requires the BlakYaks **Html Reports** extension in the organization.
Organization-wide findings remain in SARIF.

See [Project assessment HTML](../docs/project-health.md) for fields, evaluated
pass-rate semantics, collection requirements, and verification. The companion
three-tab dashboard is legacy pending an accepted live cutover; this source
change does not establish deployment or authorize repository retirement.

## Configure the assessment pipeline

The deployed assessment pipeline is in the
[`PSRule.Rules.AzureDevOps` Azure DevOps project](https://dev.azure.com/ai-experiments/PSRule.Rules.AzureDevOps).
It uses the protected Library variable group `ai-credentials`.

1. Configure `ai-credentials` with these service-principal values:

   | Variable | Description |
   | --- | --- |
   | `Directory (tenant) ID` | Microsoft Entra tenant ID for the service principal. |
   | `Application (client) ID` | Microsoft Entra application (client) ID. |
   | `secret` | Service-principal client secret; mark this variable secret. |

2. Grant the service principal sufficient read access to the organization and
   each project that should be assessed.
3. Authorize the `PSRule Azure DevOps Assessment` pipeline to use the
   variable group. The pipeline sets `ADO_ORGANIZATION` to `ai-experiments`
   and `ADO_ORGANIZATION_ID` to `3b022c28-683d-4d7e-87a5-bd8198332011`.

The pipeline installs PSRule 2.9.0, imports the checked-out module, and exports
organization data under the artifact staging directory's `outputs/targets/`
(or a retained timestamp subdirectory).
It uses strict collection completeness checks before evaluating
`Baseline.Default`. The `psrule-results` artifact contains
`outputs/collection-status.json` and, when evaluation and projection reach the
exporter, `psrule-results.sarif`, `assessment-results.json`, and
`psrule-report.html` in the same run directory. JSON retains per-project
correlation, explicit unavailable evidence, rule/severity versions, source
revision, and history comparison keys; the static HTML does not compare history.
The published staging directory also contains collected `targets/`; restrict
artifact access accordingly. Report publication runs even when collection fails.

Assessment failures mark the pipeline as **partially succeeded** through the
assessment task's `continueOnError` setting. Incomplete collection writes the
completeness report and prevents rule evaluation and HTML generation; owned
current reports, including stale HTML, are cleaned before recollection. Available
reports are still published. See
[assessment completeness](../docs/assessment-completeness.md) for report details.
Open the artifact with the Azure DevOps SARIF Viewer extension if installed.

The pipeline uses the Microsoft-hosted `Azure Pipelines` pool with the
`ubuntu-latest` image. Each job receives a fresh VM; a local agent listener is
not required. Hosted capacity and pipeline authorization are configured in Azure
DevOps. See [hosted agents](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops).

![Sarif Viewer](../assets/media/sarif-0.0.11.png)

See [assessment reporting](../docs/assessment/reporting.md) before comparing revised scores. Unknown evidence and pending severity classification keep SecurityScore unavailable; a changed policy or denominator is not compliance improvement.
