# Assessment collection completeness

Use `-CompletenessReportPath` on `Export-AzDevOpsRuleData` or
`Export-AzDevOpsOrganizationRuleData` to write a separate JSON report of collection
outcomes. Keep the report outside `OutputPath`; the commands reject a report path
inside that directory so PSRule only receives assessment targets. The report's
parent directory must already exist.

Use `-Strict` to attempt all collectors, retain available targets, and then throw
if any required collection is incomplete. Organization exports attempt every
discovered project before enforcing strict mode. The report is written before
strict mode throws, so it remains available for pipeline artifact publication.
Report-writing failures terminate the command as well.

Without `-Strict`, exporter failures continue to produce errors and warnings while
other exporters run; incomplete coverage also produces a summary warning.
Aggregate failure messages identify the command without copying exception text.
Without `-CompletenessReportPath`, no report file is created.
Neither option adds status objects to the success stream, including `-PassThru`.

## Pipeline example

After importing the local module and connecting with `Connect-AzDevOps`, use a
fresh output directory for each assessment. This avoids evaluating files left by
an earlier export. In an Azure Pipelines PowerShell task, a terminating strict-mode
error stops rule evaluation and fails the task; publish the report with an
`always()` artifact step.

```powershell
$ErrorActionPreference = 'Stop'
$runDirectory = Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY ([guid]::NewGuid().ToString())
$targetDirectory = Join-Path $runDirectory 'targets'
New-Item -Path $targetDirectory -ItemType Directory -Force | Out-Null
$completenessPath = Join-Path $runDirectory 'collection-status.json'

Export-AzDevOpsOrganizationRuleData `
    -Organization $env:ADO_ORGANIZATION `
    -OrganizationId $env:ADO_ORGANIZATION_ID `
    -OutputPath $targetDirectory `
    -CompletenessReportPath $completenessPath `
    -Strict

$inputFiles = @(Get-ChildItem $targetDirectory -File -Recurse -Filter '*.json' | Select-Object -ExpandProperty FullName)
Assert-PSRule -InputPath $inputFiles -Module DevOpsTools.AzureDevOps.PSRule
```

For one project, use the same options with
`Export-AzDevOpsRuleData -Project <project>`. `-Strict` can also be used without a
report path when only a terminating completion check is needed.

## Report contract

`SchemaVersion` is `1`. The report contains `Organization`, overall `Status`, and
`Projects`. Each project contains `Project`, `Status`, and `Collectors`; each
collector contains `Command`, `Status`, and `ReasonCodes`. `OrganizationCollection`
contains separate organization `Status` and `Collectors` records. Organization exports
also contain a `ProjectDiscovery` record for `Get-AzDevOpsProject`.

| Collector status | Meaning | Complete for strict mode? |
| --- | --- | --- |
| `Completed` | Retrieval/export completed without a detected coverage omission | Yes |
| `Empty` | Retrieval succeeded and the collection contained no resources | Yes |
| `Partial` | Some required enrichment or response fields were unavailable | No |
| `Unavailable` | Required collection was skipped or its data provider was absent | No |
| `Failed` | Retrieval or export raised an error | No |

Overall and project statuses are `Complete`, `Partial`, or `Unavailable`.
`Complete` includes legitimate empty collections. `Unavailable` means no collector
provided usable coverage; `Partial` means some coverage was usable but some was
missing. Successful project discovery alone does not make failed exports usable.
An organization with a successfully retrieved empty project list is `Complete`
only when organization collection also completes. Organization data is collected
once into the export root; each project has its own subdirectory. Single-project
exports retain organization targets in the supplied output directory.

Reason codes identify conditions without including credentials, raw responses, or
exception messages: `EmptyCollection`, `PermissionDenied`, `MissingRequiredData`,
`YamlUnavailable`, `CollectorFailed`, `ProjectDiscoveryFailed`, and
`ProjectExportFailed`, and `OrganizationExportFailed`.
Organization request failures additionally use `EndpointUnavailable`,
`RequestFailed`, `MalformedResponse`, and `SchemaChanged`.

Required settings must be present and non-null. Legitimately nullable fields,
such as an unset organization description or an unconfigured billing subscription,
do not count as missing. Missing enrichment is `Partial`; a response containing no
required data is `Unavailable`.

Permission omissions count as incomplete even when the configured token profile
intentionally prevents access. For example, ReadOnly environment exports are
`Unavailable`; omitted repository or pipeline ACLs are `Partial`. Strict mode
checks all configured collectors; this version has no optional-collector list.

Project, pipeline, environment, group, variable-group, release-definition, branch,
and policy discovery follow continuation headers. A missing or failed later page
fails collection. Completeness still does not prove retry resilience or complete
coverage of undocumented remote behavior. A collected false or
unset setting may still fail a rule; that is a finding, not a retrieval failure.

## Organization response validation

Organization overview, billing, security-policy and pipeline-settings readers
share request failure classification. HTTP 401/403 or sign-in HTML records
`Unavailable`/`PermissionDenied`; HTTP 404/410/429 or server errors record
`Unavailable`/`EndpointUnavailable`. Other request failures use `RequestFailed`,
and invalid JSON uses `MalformedResponse`. These statuses survive aggregate
collection; unexpected collector exceptions still use `Failed`/`CollectorFailed`.
Request exceptions are replaced with stable diagnostics before propagation, so
response bodies and request credentials do not enter those messages or reports.

Missing fields retain `MissingRequiredData`. Unexpected setting types become null
or are omitted and record `SchemaChanged`; a string such as `"false"` never becomes
boolean evidence. Valid false values and legitimately nullable fields remain usable.
Strict export still attempts remaining collectors, writes the report, then rejects
incomplete collection. The organization portal and commerce dependencies remain
internal contracts; these checks detect failures and schema drift without making
them optional or supplying passing defaults.

## Versioned collection endpoints

Repository Advanced Security uses Microsoft's documented
[Repo Enablement GET](https://learn.microsoft.com/en-us/rest/api/azure/devops/advancedsecurity/repo-enablement/get?view=azure-devops-rest-7.2)
with `includeAllProperties=true` and `7.2-preview.3`, replacing the portal
Contribution provider. The existing `Ghas.advSecEnabled` output is true when both
Code Security and Secret Protection are enabled; `Ghas.blockPushes` retains the
secret-protection flag. Missing or nonboolean flags remain null and incomplete.
ReadOnly/FineGrained restrictions are unchanged, and an API failure does not fall
back to portal evidence. The documented OAuth scope is `vso.advsec`; identity
permissions still apply, and this endpoint remains preview.

Project [General Settings](https://learn.microsoft.com/en-us/rest/api/azure/devops/build/general-settings/get?view=azure-devops-rest-7.1),
[Retention](https://learn.microsoft.com/en-us/rest/api/azure/devops/build/retention/get?view=azure-devops-rest-7.1)
and [Build Settings](https://learn.microsoft.com/en-us/rest/api/azure/devops/build/settings/get?view=azure-devops-rest-7.1)
use stable `7.1` contracts. General Settings documents `vso.project`, while
Retention and Build Settings document `vso.build`. Repository
[Pipeline Permissions](https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/pipeline-permissions/get?view=azure-devops-rest-7.1)
uses explicit `7.1-preview.1` and documents `vso.build`.
