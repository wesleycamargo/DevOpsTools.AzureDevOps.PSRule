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
