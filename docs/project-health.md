# Project Health & Compliance integration

The companion [dashboard repository](https://github.com/wesleycamargo/PSRule.Dashboards.AzureDevOps_)
turns this module's detailed assessment results into one offline HTML report with
**Project Health**, **Compliance Readiness** and **Evolution** tabs. Shared filters
and a drill-down drawer connect project, category, rule and finding evidence.
Static essentials remain readable when scripts are disabled. No runtime network
requests or separate web hosting are required.

## Open the validated report

Open [pipeline run 121](https://dev.azure.com/ai-experiments/PSRule.Rules.AzureDevOps/_build/results?buildId=121&view=blakyaks.azure-pipelines-html-reports.build-html-reports-tab)
and select **Project Health & Compliance**. This is existing classic definition
**17**, revision **15**, in the `PSRule.Rules.AzureDevOps` Azure DevOps project.
The rule source was `fix/assessment-trust` at
`164726afbb48861b9abad768834fd9ba17f524d8`; the reporter is reviewed separately on
dashboard branch `feature/project-health-dashboard`, based on
`feat/assessment-analytics`. These branches are not assumed merged into `main`.

Runs 120 and 121 succeeded in **report-only** mode on `devcontainer-agent` in the
development container. Run 121 assessed 645 checkpoints: 257 Pass and 388 Fail.
Its HTML attachment was downloaded and tested in a sandboxed iframe: all tabs,
filters, theme, measured ordering and the run 120 comparison passed, with no page
errors or external requests. The like-for-like comparison matched 645 checkpoints
and retained 388 persistent failures without claiming improvement. Monitor
ingestion was skipped. An authenticated portal-browser click-through was not
automated; report registration and the exact published attachment were verified.

The `psrule-results` artifact contains:

- `psrule-dashboard.html`: portable display with embedded styles, script and data.
- `psrule-summary.md` and `psrule-results.sarif`: existing summary and rule evidence.
- `collection-status.json`: completeness evidence separate from rule inputs.
- `assessment-snapshot.json` and `assessment-history.json`: retained comparison evidence.

Run/artifact permissions and retention apply. Download the HTML to view it
offline; preserve required evidence before retention expires. The HTML display
schema is **2.0**; persisted snapshots/history remain **1.0**.

## Interpret priorities and effort

Compliance is Pass / (Pass + Fail). Outstanding controls are distinct failing
rules. Organization-wide findings stay separate from project scores. Missing
collection is not a pass; legacy or incompatible evidence does not establish
improvement. Resolution requires an explicit later Pass with comparable evidence.

The dashboard's `config/effort.json` ships unset. Effort is an estimate from
reviewed configuration, not a rule result, severity score or delivery-time promise.
When no failing control in the selected scope has a known estimate, the report
hides the effort panel, estimate badges and effort-based tiers. Remediation order
uses projects with failures first, highest failing severity, most shared controls,
fewest outstanding controls, then lowest compliance. Shared controls fail in at
least three selected projects by default. Projects without failures follow.

With partial estimates, unclassified controls remain Unknown and affected
projects remain Needs estimate. Reviewed estimates enable the existing
Quick win / Planned / Needs estimate / Compliant ordering. Rule overrides take
precedence over category defaults. Review individual rule assumptions with owners
before configuring them; do not infer effort from severity or assign broad
category estimates just to replace Unknown.

The dashboard [effort review](https://github.com/wesleycamargo/PSRule.Dashboards.AzureDevOps_/blob/feature/project-health-dashboard/docs/effort-review.md)
contains proposals only. They are not loaded as configuration. Exact definitions,
thresholds and provenance are maintained in the [dashboard guide](https://github.com/wesleycamargo/PSRule.Dashboards.AzureDevOps_/blob/feature/project-health-dashboard/docs/project-health.md).

## Ownership and operational handover

This repository owns module exports, rules, baselines and rule help. The dashboard
repository owns report generation, HTML/JS/CSS, effort configuration, snapshot
projection and history acquisition. Neither the module-publication pipeline nor
this repository's weekly `psrule-assessment.yml` generates the three-tab HTML.
The [pipeline README](../pipelines/README.md) documents that separate workflow.

Classic definition 17 embeds a compressed source bundle. A rules branch change
does not update dashboard code. Generate its bootstrap from the reviewed dashboard
checkout with `src/scripts/New-ProjectHealthPipelineBundle.ps1`; preserve the
existing task environment, artifact/report publication and report-only override
when applying an approved update. The [classic pipeline handover](https://github.com/wesleycamargo/PSRule.Dashboards.AzureDevOps_/blob/feature/project-health-dashboard/docs/project-health.md#updating-existing-classic-pipeline-17)
documents the sequence and verification.

The validated agent used a temporary working directory and `run.sh --once`;
its listener exited after each job. Automatic startup is not implemented. The
[devcontainer agent plan](https://github.com/wesleycamargo/PSRule.Dashboards.AzureDevOps_/blob/feature/project-health-dashboard/docs/assessment-analytics.md#plan-build-agent-in-the-devcontainer)
covers persistent state, valid environment names, a single listener, graceful
shutdown and rebuild validation. No credentials or raw organization exports belong
in repository documentation or fixtures.
