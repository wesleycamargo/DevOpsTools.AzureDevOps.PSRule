# Project assessment HTML

The module's [assessment pipeline](../pipelines/psrule-assessment.yml) writes
`psrule-report.html` beside `assessment-results.json` and `psrule-results.sarif`.
The report is one UTF-8 HTML document titled **Azure DevOps project assessment**,
with embedded CSS and no JavaScript, external assets, network requests, or runtime
dependencies. No companion dashboard repository, Azure Monitor ingestion, web
hosting, or HTML Reports extension is required.

## Generate a report

Use a checkout containing the HTML implementation; this guide does not establish
that the published Gallery package contains it. From the repository root, load
PSRule 2.9.0 (the pipeline pin) and the local module:

```powershell
Import-Module PSRule -RequiredVersion 2.9.0
Import-Module ./src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1 -Force
```

Keep the dependency pin aligned with the reviewed pipeline and test requirements;
upgrade it only with corresponding validation. Use the existing strict collection
and detailed PSRule evaluation step to supply:

- `$assessmentResults`: detailed `Invoke-PSRule -Outcome All` results, including
  source-file provenance. Reuse the same exported targets and baseline.
- `$exportPath`: the collected `targets/` directory, with immediate project
  subdirectories. Evaluate only target files, not their parent report directory.
- `$assessmentPath`: the destination `assessment-results.json` path; its parent
  directory must already exist.
- `$organization` and `$sourceRevision`: the assessed organization and source
  revision for this run.
- `$completenessPath`: this run's `collection-status.json`, outside `targets/`,
  whose `Status` must be `Complete`.

```powershell
$assessment = Export-AzDevOpsAssessmentRun -Result $assessmentResults -ExportPath $exportPath `
    -OutputPath $assessmentPath -Organization $organization `
    -SourceRevision $sourceRevision -Baseline Baseline.Default `
    -HtmlOutputPath (Join-Path (Split-Path $assessmentPath -Parent) 'psrule-report.html') `
    -CollectionStatusPath $completenessPath
```

`-HtmlOutputPath` is optional; existing callers still receive the same assessment
object and JSON without HTML. `-CollectionStatusPath` is required when HTML is
requested. The private renderer in `Functions/AssessmentHtml.ps1` presents the
existing projection; it does not collect evidence or re-evaluate rules. JSON and
SARIF formats remain unchanged. Keep authentication credentials in protected
pipeline variables or service connections, never in examples or report inputs.

## Read the report

The report covers **project projections only**, not an organization-wide score.
Findings from export-root organization files remain in `psrule-results.sarif`;
they are not added to the existing per-project JSON projection or HTML.

- **Run metadata:** organization, source revision, baseline, rule-set version,
  severity-policy version, and collection status. No generated timestamp or new
  assessment schema fields are added.
- **Diagnostic totals:** Pass, Fail, Unknown, and NotApplicable across projects,
  repeated for each project. Missing evidence is not a pass.
- **Evaluated pass rate:** `Pass / (Pass + Fail)`, shown as a percentage or
  `Unavailable` when `Pass + Fail` is zero. Unknown and NotApplicable are
  excluded from this denominator but remain visible in the counts. This is not
  overall compliance, coverage, or a security score.
- **Project details:** scope identifier and the existing `SecurityScore` from the
  assessment summary. A null score is `Unavailable`, never zero; a real zero
  remains zero. See [assessment reporting](assessment/reporting.md) for scoring
  semantics.
- **Findings needing attention:** Fail and Unknown findings only, sorted by rule
  and target. Columns are rule, target, outcome, severity (or `Unclassified`), and
  reason code. No raw payloads or `RawReasons` are embedded. All input-derived
  display strings are HTML-encoded; targets are not turned into links.
- **Empty states:** no project results and no failing or unknown findings are
  stated explicitly, rather than implying complete coverage or full compliance.

This is a per-run static view, not a feature-parity dashboard migration. There
are no tabs, filters, effort estimates, charts, history comparisons, or Workbooks.
Retaining dated output directories does not add history analysis to the HTML.

## Download and verify

Download the **`psrule-results`** artifact from the assessment run. Open
`outputs/psrule-report.html` locally, or
`outputs/yyyy-MM-dd-HH-mm/psrule-report.html` when `KeepResults` was enabled.
The JSON, collection status, and SARIF are beside it in the same run directory,
not under `targets/`.

Check that collection status is `Complete`, report metadata agrees with
`assessment-results.json`, and project counts agree with its findings. Use SARIF
for organization-wide findings. Open the downloaded HTML offline to verify it
remains readable without a network connection. Project/resource identifiers are
still sensitive: artifact permissions and retention apply even though raw
payloads are excluded from HTML. Preserve required evidence before expiry.

Passing and failing assessments both produce HTML when the exporter is reached.
Incomplete strict collection stops before projection/report generation and
retains `collection-status.json` instead of presenting a success report. The
pipeline cleans owned current outputs, including stale HTML, before recollection;
it preserves retained runs and unrelated files. Collection, engine, projection,
and rendering errors remain errors. Existing `continueOnError` and unconditional
artifact publication behavior is unchanged; an artifact is not proof of success.

## Legacy workflow and retirement gate

The companion dashboard workflow is **legacy pending an accepted live cutover**.
Its repository remains a retirement candidate, not an archived or replaced live
service. The three-tab dashboard, snapshot/history workflow, Azure Monitor
resources, and Workbooks are not migrated by this implementation.

Before retirement, separately authorize and inspect the actual live definition,
repository, branch, YAML, and schedules; definition numbers alone do not identify
the correct workflow. Accept a real replacement run after downloading its HTML,
JSON, collection status, and SARIF, checking their agreement and offline display,
and explicitly accepting the reduced functionality. Only then authorize disabling
the old workflow and archiving its repository. Preserve historical evidence;
resource teardown needs separate inventory and approval. Local implementation or
offline tests do not establish deployment or live acceptance.
