# Beginner guide: assess Azure DevOps with Azure PowerShell and Microsoft Entra authentication

Run this repository's security assessment without a PAT, without Azure CLI, and without an Azure subscription. This guide includes the corrections made during our terminal walkthrough.

## 1. What happens

```text
Connect-AzAccount       Sign in as yourself in Microsoft Entra ID
Get-AzAccessToken      Request a token for Azure DevOps
Connect-AzDevOps       Give the token to this repository's module
Export-AzDevOpsRuleData  Save project and organization configuration evidence
collection-status.json  Check collection coverage
Assert-PSRule          Evaluate rules against explicit JSON evidence files
Invoke-PSRule          Inspect findings as PowerShell objects
```

Three modules do different jobs:

- **Az.Accounts:** sign-in and token acquisition.
- **DevOpsTools.AzureDevOps.PSRule:** this repository's collectors and rules.
- **PSRule:** the rule engine, including `Assert-PSRule` and `Invoke-PSRule`.

Collection needs network access and authentication. Evaluating saved evidence can be done offline. A token represents your identity: it does not grant additional Azure DevOps permissions.

## 2. Prerequisites and terminal basics

You need PowerShell, a local checkout of this repository, internet access for module installation/sign-in/collection, and an account authorized to read your Azure DevOps organization and project. Some organization settings and permission data require additional privileges.

For this walkthrough, use **PowerShell 7**, started with `pwsh`. Do not execute these commands in Bash or Command Prompt. Only copy code, not prompt characters such as `❯` or `>`.

Keep the same PowerShell terminal open throughout: variables disappear when the session closes. Execute each code block in order. Most commands are single lines to avoid terminal continuation problems.

Change to your repository root (the directory containing `README.md`, `src`, `tests`, and `docs`):

```powershell
# Replace this path if your checkout is elsewhere.
Set-Location /workspaces/DevOpsTools.AzureDevOps.PSRule
Get-Location
$PSVersionTable.PSVersion
```

Gather these values before continuing:

| Value | Meaning |
| --- | --- |
| Tenant ID | Microsoft Entra tenant GUID associated with your Azure DevOps organization. Ask your administrator if unknown. |
| Organization | Organization name, not its full URL. In `https://dev.azure.com/example-org`, it is `example-org`. |
| Project | Exact Azure DevOps project name. |

You do not need an Azure subscription, PAT, or `az` executable.

## 3. Install and import the modules

Install these once. PSRule **2.9.0** is the version pinned in the repository's `tests/requirements.psd1`.

```powershell
Install-Module Az.Accounts -Scope CurrentUser -Repository PSGallery
Install-Module PSRule -RequiredVersion 2.9.0 -Scope CurrentUser -Repository PSGallery
```

Follow your organization's package installation policy if asked to trust the Gallery. `CurrentUser` installs for your user rather than all users.

Import dependencies and this checkout:

```powershell
Import-Module Az.Accounts
Import-Module PSRule -RequiredVersion 2.9.0
Import-Module ./src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psd1 -Force
Get-Command Connect-AzAccount, Get-AzAccessToken, Connect-AzDevOps, Export-AzDevOpsRuleData, Assert-PSRule
```

The last command should list all five commands. No module compilation step is required. Pester is for repository tests, not this manual assessment.

## 4. Set your values

Replace the placeholders, keeping the quotes:

```powershell
$tenantId = '<your-entra-tenant-guid>'
$organization = '<your-azure-devops-organization-name>'
$project = '<your-project-name>'
```

## 5. Sign in without subscription discovery

```powershell
Connect-AzAccount -Tenant $tenantId -SkipContextPopulation -UseDeviceAuthentication
```

Follow the device-code instructions printed in your own terminal and complete sign-in in a browser. Use an account with access to the target Azure DevOps organization. Do not share the sign-in code.

- `-Tenant` selects your Microsoft Entra tenant.
- `-SkipContextPopulation` skips subscription-context population. Do not add a subscription-selection step.
- `-UseDeviceAuthentication` uses device-code authentication rather than the interactive-browser path that failed during this walkthrough with a native `msalruntime` loading error.

If your tenant's Conditional Access policies disallow device-code authentication, ask your administrator for an approved sign-in method. Do not weaken security policy to follow this guide.

## 6. Obtain a token for Azure DevOps

```powershell
$azToken = Get-AzAccessToken -TenantId $tenantId -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798'
$accessToken = [System.Net.NetworkCredential]::new('', $azToken.Token).Password
```

The resource ID identifies Azure DevOps. Do not substitute an Azure Resource Manager token.

Current Az.Accounts returns the token as a `SecureString`; this checkout's `Connect-AzDevOps -AccessToken` accepts a string. The second command converts the token without displaying it and works with either secure-string or string values.

**Do not print `$accessToken`, save it, commit it, or include it in a screenshot.** Conversion places a plain-text copy in process memory. Removing variables later is cleanup, not a guarantee of secure memory erasure.

This one-line conversion replaces the earlier multi-line `if/else` example that failed when submitted interactively in the terminal.

## 7. Connect the repository module

```powershell
Connect-AzDevOps -Organization $organization -AccessToken $accessToken
```

The command verifies access against the projects API and resolves the organization GUID if needed. Returning without output is not necessarily an error.

For this checkout, the correct bearer parameter is `-AccessToken`, not `-PAT`, `-BearerToken`, or `-AuthType`. The implementation is in `src/DevOpsTools.AzureDevOps.PSRule/Functions/Common.ps1`.

The `TokenType` option is the module's collector permission profile, not an OAuth scope or a permission grant. This walkthrough leaves it at its default so default coverage is attempted; actual API access still depends on your identity.

## 8. Prepare output paths

Default runs clean and reuse current results in `outputs/`. Set `$keepResults` to
`$true` to preserve a dated run in `outputs/yyyy-MM-dd-HH-mm/` instead.

```powershell
$keepResults = $false
. ./src/DevOpsTools.AzureDevOps.PSRule/Functions/AssessmentOutput.ps1
$layout = Get-AzDevOpsAssessmentRunPaths -OutputRoot (Join-Path $PWD 'outputs') -KeepResults:$keepResults
$runDirectory = $layout.RunDirectory
$targets = $layout.OutputPath
$coverage = $layout.CompletenessReportPath
$runDirectory
```

```text
outputs/                    Current results (or a dated child with retention enabled)
  collection-status.json    Collection coverage report
  targets/                  JSON and YAML evidence
```

Cleanup preserves dated history and unrelated files. Retained same-minute runs
stop rather than overwrite. Keep the coverage report outside `targets`: it is not
a rule target. Exports may contain sensitive organizational configuration;
restrict access and do not commit them.

## 9. Run collection and assessment under one output lock

Do not initialize the output directory in a standalone command. Run the entire
output-producing workflow in one `try`/`finally` scope so an export, rule, or
report-writing failure always releases the mutex.

```powershell
$runLock = $null
try {
    $runLock = Initialize-AzDevOpsAssessmentRunDirectory -RunDirectory $runDirectory -KeepResults:$keepResults

    Export-AzDevOpsRuleData -Project $project -OutputPath $targets -CompletenessReportPath $coverage -Strict

    $report = Get-Content -LiteralPath $coverage -Raw | ConvertFrom-Json
    if ($report.Status -ne 'Complete') { throw 'Collection is incomplete. Resolve the report findings before evaluating rules.' }

    $inputFiles = @(Get-ChildItem -LiteralPath $targets -File -Recurse -Filter '*.json' | Select-Object -ExpandProperty FullName)
    if ($inputFiles.Count -eq 0) { throw 'No JSON evidence files found. Check the target directory and export.' }

    $results = @(Invoke-PSRule -InputPath $inputFiles -Format Json -Module DevOpsTools.AzureDevOps.PSRule -Baseline Baseline.Default)
    if ($results.Count -eq 0) { throw 'Zero rule results. No assessment can be claimed.' }
    ConvertTo-Json -InputObject $results -Depth 30 | Set-Content -LiteralPath (Join-Path $runDirectory 'rule-results.json') -Encoding utf8

    $sarifPath = Join-Path $runDirectory 'results.sarif'
    Invoke-PSRule -InputPath $inputFiles -Format Json -Module DevOpsTools.AzureDevOps.PSRule -Baseline Baseline.Default -OutputFormat Sarif -OutputPath $sarifPath
}
finally {
    Release-AzDevOpsAssessmentRunLock -RunLock $runLock
}
```

This collects project configuration, repositories and policies, pipelines, environments and checks, service connections, variable groups, groups, classic releases, and retention settings, plus organization settings.

`-Strict` attempts the collectors, retains available evidence, writes the completeness report, then throws if required coverage is incomplete. **If it fails, inspect coverage before evaluating rules.**

## 10. Check collection status

```powershell
$report = Get-Content -LiteralPath $coverage -Raw | ConvertFrom-Json
$report | Select-Object Organization, Status
$report.Projects | Select-Object Project, Status
$report.OrganizationCollection | Select-Object Status
```

For project collector details, copy this complete block together:

```powershell
$report.Projects | ForEach-Object {
    $projectName = $_.Project
    $_.Collectors | Select-Object @{Name='Project'; Expression={$projectName}}, Command, Status, ReasonCodes
} | Format-List
```

For organization collector details:

```powershell
$report.OrganizationCollection.Collectors | Select-Object Command, Status, ReasonCodes | Format-List
```

| Collector status | Meaning | Complete for strict mode? |
| --- | --- | --- |
| `Completed` | Collection completed without a detected coverage omission | Yes |
| `Empty` | Retrieval succeeded but found no resources | Yes |
| `Partial` | Some required evidence is missing | No |
| `Unavailable` | Required collection was inaccessible or skipped | No |
| `Failed` | Retrieval/export raised an error | No |

`EmptyCollection` for variable groups or classic release definitions is not an export failure. `PermissionDenied` needs access review; `EndpointUnavailable` indicates an endpoint problem. Resolve incomplete collection instead of treating missing evidence as a pass.

Before proceeding:

```powershell
if ($report.Status -ne 'Complete') { throw 'Collection is incomplete. Resolve the report findings before evaluating rules.' }
```

See `docs/assessment-completeness.md` in the repository for the complete status contract. A complete report means no detected required coverage omission, not proof of exhaustive security coverage.

## 11. Run rules against explicit JSON files

**Important correction:** in the reproduced PSRule 2.9.0 run, a directory-only input produced zero evaluations. Explicit JSON file paths worked.

```powershell
$inputFiles = @(Get-ChildItem -LiteralPath $targets -File -Recurse -Filter '*.json' | Select-Object -ExpandProperty FullName)
if ($inputFiles.Count -eq 0) { throw 'No JSON evidence files found. Check the target directory and export.' }
$inputFiles.Count
Assert-PSRule -InputPath $inputFiles -Format Json -Module DevOpsTools.AzureDevOps.PSRule -Baseline Baseline.Default
```

This walkthrough evaluates the JSON evidence. It does not separately evaluate the exported pipeline YAML files; YAML-specific checks require a separate YAML input selection.

Interpret the summary correctly:

- **Processed greater than zero:** rules ran. Several rules may apply to one file, so this is not a file count.
- **Failed:** configuration did not satisfy a rule. These are findings, not automatically execution problems.
- **Errored:** rule execution errors need investigation.
- **Zero processed:** not proof that the project passed. Check input files, rules, target types, and baseline.

`Assert-PSRule` enforces assertions: failing rules can fail an automated job. Use `Invoke-PSRule` below to inspect result objects.

## 12. Inspect findings

```powershell
$results = @(Invoke-PSRule -InputPath $inputFiles -Format Json -Module DevOpsTools.AzureDevOps.PSRule -Baseline Baseline.Default)
$results | Group-Object Outcome | Select-Object Name, Count
$results | Where-Object Outcome -EQ 'Fail' | Select-Object RuleName, TargetName, Outcome | Format-Table -AutoSize
```

Find remediation guidance in `src/DevOpsTools.AzureDevOps.PSRule/en/`: rule-help filenames match rule IDs. Some rules also have Dutch help under `nl/`.

The protected block above writes optional SARIF output to `results.sarif` alongside `rule-results.json`. Inspect it after the block completes:

```powershell
Get-Item -LiteralPath (Join-Path $runDirectory 'results.sarif') | Select-Object Name, Length
```

Keep the coverage report with results so readers know whether the scan had complete collection.

## 13. Clean up and resume later

```powershell
Disconnect-AzDevOps
Remove-Variable accessToken, azToken -ErrorAction SilentlyContinue
Disconnect-AzAccount -Scope Process | Out-Null
```

This is session cleanup, not token revocation. If the bearer token expires, request another token and reconnect. Do not assume a copied token refreshes itself.

To evaluate saved data in a new session, repeat the PSRule/local module imports, point `$targets` at the saved run's `targets` directory, inspect the associated report, and repeat explicit JSON file selection. No sign-in is needed unless collecting fresh data.

## Corrections made during the walkthrough

| Problem | Working change |
| --- | --- |
| Original instructions used a PAT | Switched to Microsoft Entra authentication and `-AccessToken`. |
| Azure CLI was not installed | Switched to Azure PowerShell's `Az.Accounts` module. |
| Tenant has no subscriptions | Removed subscription selection; specified tenant and `-SkipContextPopulation`. |
| `InteractiveBrowserCredential` could not load `msalruntime` | Switched to `-UseDeviceAuthentication`; this avoids the failing path, not a repair of the missing library. |
| Terminal reported `else` was not recognized | Replaced the multi-line token conversion with `NetworkCredential` on one line. For terminal conditionals, keep `} else {` together or execute the complete script. |
| `Assert-PSRule` was not recognized | Installed/imported the separate PSRule engine, pinned to 2.9.0. |
| Exports appeared to fail | Checked `collection-status.json`; the inspected report was complete, with legitimate empty variable groups and classic releases. |
| Rules processed was zero | Passed explicit JSON input filenames with `-Format Json` instead of the directory alone. |

These are command/workflow corrections. No runtime implementation change to this module was needed to reproduce the working JSON evaluation. Other existing local repository modifications are not attributed to this walkthrough.

## Observed result from the saved walkthrough export

The report for organization `ai-experiments`, project `Pipelines`, at `out/7ee00577-4249-4821-bae3-1df9d393daac/collection-status.json` showed complete project and organization collection. Variable groups and classic releases were `Empty` with `EmptyCollection`.

Offline evaluation with PSRule 2.9.0 and the local module returned:

| Measurement | Observed value |
| --- | ---: |
| JSON input files | 18 |
| Rule evaluations | 166 |
| Passed | 48 |
| Failed | 118 |
| Errored | 0 |

These values describe that saved export only, not expected results for every run. Interactive sign-in was performed by the learner; the assistant independently verified module commands and offline evaluation, not a separate live sign-in.

## References

- Microsoft Learn: Connect-AzAccount — https://learn.microsoft.com/en-us/powershell/module/az.accounts/connect-azaccount
- Microsoft Learn: Get-AzAccessToken — https://learn.microsoft.com/en-us/powershell/module/az.accounts/get-azaccesstoken
- Microsoft Learn: Entra tokens for Azure DevOps — https://learn.microsoft.com/en-us/azure/devops/cli/entra-tokens?view=azure-devops
- Repository: `docs/assessment-completeness.md`, `docs/architecture.md`, and `tests/requirements.psd1`.
