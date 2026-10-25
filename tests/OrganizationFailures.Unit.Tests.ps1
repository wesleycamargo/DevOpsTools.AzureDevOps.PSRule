BeforeAll {
    Import-Module "$PSScriptRoot/../src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psd1" -Force
}

Describe 'Organization API failure boundaries' -Tag Unit {
    It 'records <Failure> for <Collector> without leaking response data' -ForEach @(
        foreach ($collector in 'Export-AdoOrganizationGeneralOverview', 'Export-AdoOrganizationSecurityPolicies', 'Export-AdoOrganizationPipelinesSettings', 'Export-AdoOrganizationGeneralBillingSettings') {
            foreach ($failure in 'PermissionDenied', 'EndpointUnavailable', 'MalformedResponse', 'MissingRequiredData') {
                @{ Collector = $collector; Failure = $failure }
            }
        }
    ) {
        InModuleScope PSRule.Rules.AzureDevOps -Parameters @{ Collector = $Collector; Failure = $Failure; ReportPath = "$TestDrive/status.json"; ExportPath = "$TestDrive/targets" } {
            Mock Invoke-RestMethod { [pscustomobject]@{ value = @() } }
            Connect-AzDevOps -Organization fixture-org -OrganizationId '11111111-1111-1111-1111-111111111111' -PAT fixture-secret
            Mock Invoke-WebRequest {
                if ($Failure -in 'PermissionDenied', 'EndpointUnavailable') {
                    $statusCode = if ($Failure -eq 'PermissionDenied') { 403 } else { 404 }
                    throw [Microsoft.PowerShell.Commands.HttpResponseException]::new('Bearer fixture-secret response body', [Net.Http.HttpResponseMessage]::new([Net.HttpStatusCode]$statusCode))
                }
                $content = if ($Failure -eq 'MalformedResponse') { '{fixture-secret' } else { '{}' }
                [pscustomobject]@{ Content = $content; RawContent = $content }
            }
            $report = [ordered]@{ Projects = @(); OrganizationCollection = [ordered]@{ Collectors = @() } }
            $parameters = if ($Collector -eq 'Export-AdoOrganizationGeneralBillingSettings') { @{ OrganizationId = '11111111-1111-1111-1111-111111111111' } } else { @{} }
            Invoke-AzDevOpsCollectors -ExportCommands @(@{ Name = $Collector; Params = $parameters }) -OutputPath $ExportPath -PassThru -CollectionReport $report.OrganizationCollection -OrganizationScope -ErrorAction SilentlyContinue
            { Complete-AzDevOpsAssessmentExport -Report $report -CompletenessReportPath $ReportPath -Strict } | Should -Throw '*collection is incomplete*'
            $record = $report.OrganizationCollection.Collectors[0]
            $record.Command | Should -Be $Collector
            $record.Status | Should -Be Unavailable
            $record.ReasonCodes | Should -Contain $Failure
            Get-Content $ReportPath -Raw | Should -Not -Match 'fixture-secret|response body'
        }
    }

    It 'rejects changed field types in <Reader>' -ForEach @(
        @{ Reader = 'Read-AdoOrganizationPipelinesSettings'; Payload = @{ dataProviders = @{ 'ms.vss-build-web.pipelines-org-settings-data-provider' = @{ statusBadgesArePrivate = 'false'; enforceSettableVar = $false } } }; Field = 'statusBadgesArePrivate' }
        @{ Reader = 'Read-AdoOrganizationGeneralBillingSettings'; Payload = @{ currentOrganizationName = 'fixture-org'; subscriptionStatus = $null; isEnterpriseBillingEnabled = 'false'; isAssignmentBillingEnabled = $false }; Field = 'isEnterpriseBillingEnabled' }
        @{ Reader = 'Read-AdoOrganizationGeneralOverview'; Payload = @{ fps = @{ dataProviders = @{ data = @{ 'ms.vss-admin-web.organization-admin-overview-data-provider' = @{ description = $null; geography = 'Europe'; region = @{ renamed = 'west' }; timeZone = @{ displayName = 'UTC' } }; 'ms.vss-web.page-data' = @{ user = @{ displayName = 'Fixture' } } } } } }; Field = 'region' }
    ) {
        InModuleScope PSRule.Rules.AzureDevOps -Parameters @{ Reader = $Reader; Payload = $Payload; Field = $Field } {
            Mock Invoke-WebRequest {
                $json = $Payload | ConvertTo-Json -Depth 10
                [pscustomobject]@{ Content = $json; RawContent = $json }
            }
            $parameters = if ($Reader -eq 'Read-AdoOrganizationGeneralBillingSettings') { @{ OrganizationId = '11111111-1111-1111-1111-111111111111' } } else { @{ Organization = 'fixture-org' } }
            $script:collectionStatus = [ordered]@{ Status = 'Completed'; ReasonCodes = @() }
            try {
                $settings = & $Reader @parameters -AccessToken fixture-token
                $settings.$Field | Should -BeNullOrEmpty
                $script:collectionStatus.Status | Should -Be Partial
                $script:collectionStatus.ReasonCodes | Should -Contain SchemaChanged
            } finally { $script:collectionStatus = $null }
        }
    }

    It 'does not convert an invalid security policy value into compliant evidence' {
        InModuleScope PSRule.Rules.AzureDevOps {
            Mock Invoke-WebRequest {
                $json = @{ fps = @{ dataProviders = @{ data = @{ 'ms.vss-admin-web.organization-policies-data-provider' = @{ policies = @{ fixture = @(@{ policy = @{ name = 'Policy.DisallowSecureShell'; effectiveValue = 'false' } }) } } } } } } | ConvertTo-Json -Depth 10
                [pscustomobject]@{ Content = $json; RawContent = $json }
            }
            $script:collectionStatus = [ordered]@{ Status = 'Completed'; ReasonCodes = @() }
            try {
                $settings = Read-AdoOrganizationSecurityPolicies -Organization fixture-org -AccessToken fixture-token
                $settings.ContainsKey('disallowSecureShell') | Should -BeFalse
                $script:collectionStatus.ReasonCodes | Should -Contain SchemaChanged
            } finally { $script:collectionStatus = $null }
        }
    }
    It 'records unexpected organization exceptions as failed after <PriorStatus> evidence' -ForEach @(
        @{ PriorStatus = 'Partial' }, @{ PriorStatus = 'Unavailable' }
    ) {
        InModuleScope PSRule.Rules.AzureDevOps -Parameters @{ PriorStatus = $PriorStatus } {
            Mock Invoke-RestMethod { [pscustomobject]@{ value = @() } }
            Connect-AzDevOps -Organization fixture-org -PAT fixture-token
            Mock Export-AdoOrganizationGeneralOverview {
                Set-AzDevOpsCollectionStatus -Status $PriorStatus -ReasonCode MissingRequiredData
                throw 'Unexpected collector failure.'
            }
            $report = [ordered]@{ Collectors = @() }
            Invoke-AzDevOpsCollectors -ExportCommands @(@{ Name = 'Export-AdoOrganizationGeneralOverview'; Params = @{} }) -OutputPath $TestDrive -CollectionReport $report -OrganizationScope 2>$null 3>$null
            $report.Collectors[0].Status | Should -Be Failed
            $report.Collectors[0].ReasonCodes | Should -Contain CollectorFailed
        }
    }

    It 'classifies <Case> and sanitizes request errors' -ForEach @(
        @{ Case = 'unauthorized'; StatusCode = 401; Reason = 'PermissionDenied' }
        @{ Case = 'gone'; StatusCode = 410; Reason = 'EndpointUnavailable' }
        @{ Case = 'throttled'; StatusCode = 429; Reason = 'EndpointUnavailable' }
        @{ Case = 'server error'; StatusCode = 503; Reason = 'EndpointUnavailable' }
        @{ Case = 'transport error'; StatusCode = 0; Reason = 'RequestFailed' }
        @{ Case = 'sign-in HTML'; StatusCode = -1; Reason = 'PermissionDenied' }
    ) {
        InModuleScope PSRule.Rules.AzureDevOps -Parameters @{ StatusCode = $StatusCode; Reason = $Reason } {
            Mock Invoke-WebRequest {
                if ($StatusCode -eq -1) { return [pscustomobject]@{ Content = '<html>Sign In fixture-secret</html>' } }
                if ($StatusCode -eq 0) { throw 'Request failed with fixture-secret.' }
                throw [Microsoft.PowerShell.Commands.HttpResponseException]::new('Request failed with fixture-secret.', [Net.Http.HttpResponseMessage]::new([Net.HttpStatusCode]$StatusCode))
            }
            $script:collectionStatus = [ordered]@{ Status = 'Completed'; ReasonCodes = @() }
            try {
                { Read-AdoOrganizationGeneralOverview -Organization fixture-org -AccessToken fixture-token -ErrorAction Stop } | Should -Throw "*($Reason)*"
                $script:collectionStatus.Status | Should -Be Unavailable
                $script:collectionStatus.ReasonCodes | Should -Contain $Reason
            } finally { $script:collectionStatus = $null }
        }
    }

}
