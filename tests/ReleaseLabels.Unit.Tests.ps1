BeforeAll {
    Import-Module PSRule -RequiredVersion 2.9.0
    Add-Type -Path (Join-Path (Get-Module PSRule).ModuleBase 'YamlDotNet.dll')
    $deserializer = [YamlDotNet.Serialization.DeserializerBuilder]::new().Build()
    $publishing = $deserializer.Deserialize([IO.StringReader]::new((Get-Content "$PSScriptRoot/../.github/workflows/publish-on-release.yml" -Raw)))
    $labelStep = $publishing['jobs']['publish']['steps'] | Where-Object { $_['name'] -eq 'Resolve pull request version labels' }
    $labelScript = $labelStep['with']['script']
    $probePath = Join-Path $TestDrive 'labels.cjs'
    @'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const fixture = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const endpoint = Symbol('listPullRequestsAssociatedWithCommit');
const outputs = {};
const github = {
    rest: { repos: { listPullRequestsAssociatedWithCommit: endpoint } },
    paginate: async (actualEndpoint, parameters) => {
        assert.equal(actualEndpoint, endpoint);
        assert.deepEqual(parameters, {owner: 'owner', repo: 'module', commit_sha: 'merge-sha', per_page: 100});
        if (fixture.FailLookup) throw new Error('GitHub unavailable');
        return fixture.PullRequests;
    }
};
const context = {repo: {owner: 'owner', repo: 'module'}, sha: 'merge-sha'};
const core = {setOutput: (key, value) => { outputs[key] = value; }};
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
(async () => {
    const run = new AsyncFunction('github', 'context', 'core', fixture.Script);
    if (fixture.FailLookup) {
        await assert.rejects(run(github, context, core), /GitHub unavailable/);
        assert.deepEqual(outputs, {});
    } else {
        await run(github, context, core);
        assert.deepEqual(JSON.parse(outputs.labels), fixture.Expected);
    }
})().catch(error => { console.error(error); process.exitCode = 1; });
'@ | Set-Content $probePath
}

Describe 'Publishing pull request label lookup' -Tag Unit {
    It 'resolves only the triggering merged pull request: <Scenario>' -ForEach @(
        @{ Scenario = 'no associated PR'; Labels = @(); Expected = @(); Merged = $false; Branch = 'main'; Repository = 'owner/module'; MergeSha = 'merge-sha'; FailLookup = $false }
        @{ Scenario = 'minor by default'; Labels = @('documentation'); Expected = @('documentation'); Merged = $true; Branch = 'main'; Repository = 'owner/module'; MergeSha = 'merge-sha'; FailLookup = $false }
        @{ Scenario = 'major label'; Labels = @('major'); Expected = @('major'); Merged = $true; Branch = 'main'; Repository = 'owner/module'; MergeSha = 'merge-sha'; FailLookup = $false }
        @{ Scenario = 'patch label'; Labels = @('patch'); Expected = @('patch'); Merged = $true; Branch = 'main'; Repository = 'owner/module'; MergeSha = 'merge-sha'; FailLookup = $false }
        @{ Scenario = 'both labels preserved for rejection'; Labels = @('major', 'patch'); Expected = @('major', 'patch'); Merged = $true; Branch = 'main'; Repository = 'owner/module'; MergeSha = 'merge-sha'; FailLookup = $false }
        @{ Scenario = 'open PR ignored'; Labels = @('major'); Expected = @(); Merged = $false; Branch = 'main'; Repository = 'owner/module'; MergeSha = 'merge-sha'; FailLookup = $false }
        @{ Scenario = 'other base branch ignored'; Labels = @('major'); Expected = @(); Merged = $true; Branch = 'develop'; Repository = 'owner/module'; MergeSha = 'merge-sha'; FailLookup = $false }
        @{ Scenario = 'other repository ignored'; Labels = @('major'); Expected = @(); Merged = $true; Branch = 'main'; Repository = 'fork/module'; MergeSha = 'merge-sha'; FailLookup = $false }
        @{ Scenario = 'other merge ignored'; Labels = @('major'); Expected = @(); Merged = $true; Branch = 'main'; Repository = 'owner/module'; MergeSha = 'other-sha'; FailLookup = $false }
        @{ Scenario = 'lookup errors stop publication'; Labels = @(); Expected = @(); Merged = $false; Branch = 'main'; Repository = 'owner/module'; MergeSha = 'merge-sha'; FailLookup = $true }
    ) {
        $pulls = @()
        if ($Labels.Count -gt 0) {
            $pulls = @(@{
                merged_at = $(if ($Merged) { '2026-11-08T00:00:00Z' } else { $null })
                base = @{ ref = $Branch; repo = @{ full_name = $Repository } }
                merge_commit_sha = $MergeSha
                labels = @($Labels | ForEach-Object { @{ name = $_ } })
            })
        }
        $fixturePath = Join-Path $TestDrive 'labels.json'
        @{
            Script = $labelScript
            PullRequests = $pulls
            Expected = $Expected
            FailLookup = $FailLookup
        } | ConvertTo-Json -Depth 10 | Set-Content $fixturePath

        & node $probePath $fixturePath

        $LASTEXITCODE | Should -Be 0
    }
}
