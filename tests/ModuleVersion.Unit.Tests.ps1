BeforeAll {
    $repositoryPath = Split-Path $PSScriptRoot -Parent
    $versionScript = Join-Path $repositoryPath 'scripts/Set-ModuleReleaseVersion.ps1'
    $moduleName = 'DevOpsTools.AzureDevOps.PSRule'
    $expectedGuid = [guid]'f77fbd3d-03be-4e42-98f3-4c185cc93bba'
}

Describe 'Automatic module release version' -Tag Unit {
    BeforeEach {
        $manifestPath = Join-Path $TestDrive "$moduleName.psd1"
        New-ModuleManifest -Path $manifestPath -ModuleVersion '0.2.2' -Guid $expectedGuid -Description 'Release version fixture' -FunctionsToExport @('Connect-AzDevOps', '*')
        Mock Find-Module { [pscustomobject]@{ Version = '0.2.2' } }
    }

    It 'defaults to a minor bump without pull request labels' {
        $before = Get-Content $manifestPath -Raw
        $result = & $versionScript -ManifestPath $manifestPath

        $result.Bump | Should -Be 'minor'
        $result.Version | Should -Be '0.3.0'
        $manifest = Import-PowerShellDataFile $manifestPath
        $manifest.ModuleVersion | Should -Be '0.3.0'
        $manifest.GUID | Should -Be $expectedGuid
        $manifest.Description | Should -Be 'Release version fixture'
        Get-Content $manifestPath -Raw | Should -BeExactly ($before.Replace("'0.2.2'", "'0.3.0'"))
        Should -Invoke Find-Module -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'DevOpsTools.AzureDevOps.PSRule' -and $Repository -eq 'PSGallery'
        }
    }

    It 'uses the <Bump> label and resets the lower version components' -ForEach @(
        @{ Labels = @('major'); Bump = 'major'; Expected = '1.0.0' }
        @{ Labels = @('patch'); Bump = 'patch'; Expected = '0.2.3' }
        @{ Labels = @('documentation', 'patch'); Bump = 'patch'; Expected = '0.2.3' }
        @{ Labels = @('documentation'); Bump = 'minor'; Expected = '0.3.0' }
    ) {
        $result = & $versionScript -ManifestPath $manifestPath -PullRequestLabels $Labels

        $result.Bump | Should -Be $Bump
        $result.Version | Should -Be $Expected
        (Import-PowerShellDataFile $manifestPath).ModuleVersion | Should -Be $Expected
    }

    It 'rejects conflicting major and patch labels before lookup or modification' {
        $before = Get-Content $manifestPath -Raw

        { & $versionScript -ManifestPath $manifestPath -PullRequestLabels @('major', 'patch') } | Should -Throw '*both major and patch*'

        Get-Content $manifestPath -Raw | Should -BeExactly $before
        Should -Invoke Find-Module -Times 0 -Exactly
    }

    It 'increments the newer of the published and checked-in versions' -ForEach @(
        @{ Published = '0.8.9'; Expected = '0.9.0'; Base = '0.8.9' }
        @{ Published = '0.1.0'; Expected = '0.3.0'; Base = '0.2.2' }
    ) {
        Mock Find-Module { [pscustomobject]@{ Version = $Published } }

        $result = & $versionScript -ManifestPath $manifestPath

        $result.BaseVersion | Should -Be $Base
        $result.Version | Should -Be $Expected
    }

    It 'does not change the manifest if Gallery lookup fails' {
        Mock Find-Module { throw 'Gallery unavailable' }
        $before = Get-Content $manifestPath -Raw

        { & $versionScript -ManifestPath $manifestPath } | Should -Throw '*Gallery unavailable*'

        Get-Content $manifestPath -Raw | Should -BeExactly $before
    }

    It 'rejects a prerelease source rather than silently publishing it as stable' {
        Update-ModuleManifest -Path $manifestPath -Prerelease 'preview1'
        $before = Get-Content $manifestPath -Raw

        { & $versionScript -ManifestPath $manifestPath } | Should -Throw '*prerelease*'

        Get-Content $manifestPath -Raw | Should -BeExactly $before
        Should -Invoke Find-Module -Times 0 -Exactly
    }
}
