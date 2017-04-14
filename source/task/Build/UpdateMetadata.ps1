BuildTask UpdateMetadata -Stage Build -Properties @{
    Implementation = {
        try {
            # Version
            Update-Metadata $buildInfo.ReleaseManifest -PropertyName ModuleVersion -Value $buildInfo.Version
            
            # RootModule
            if (Enable-Metadata $buildInfo.ReleaseManifest -PropertyName RootModule) {
                Update-Metadata $buildInfo.ReleaseManifest -PropertyName RootModule -Value $buildInfo.ReleaseRootModule.Name
            }

            # FunctionsToExport
            if (Enable-Metadata $buildInfo.ReleaseManifest -PropertyName FunctionsToExport) {
                Update-Metadata $buildInfo.ReleaseManifest -PropertyName FunctionsToExport -Value (
                    (Get-ChildItem (Join-Path $buildInfo.Source 'public') -Filter '*.ps1' -File -Recurse).BaseName
                )
            }

            # RequiredAssemblies
            if (Test-Path (Join-Path $buildInfo.Package 'lib\*.dll')) {
                if (Enable-Metadata $buildInfo.ReleaseManifest -PropertyName RequiredAssemblies) {
                    Update-Metadata $buildInfo.ReleaseManifest -PropertyName RequiredAssemblies -Value (
                        (Get-Item (Join-Path $buildInfo.Package 'lib\*.dll')).Name | ForEach-Object {
                            Join-Path 'lib' $_
                        }
                    )
                }
            }

            # FormatsToProcess
            if (Test-Path (Join-Path $buildInfo.Package '*.Format.ps1xml')) {
                if (Enable-Metadata $buildInfo.ReleaseManifest -PropertyName FormatsToProcess) {
                    Update-Metadata $buildInfo.ReleaseManifest -PropertyName FormatsToProcess -Value (Get-Item (Join-Path $buildInfo.Package '*.Format.ps1xml')).Name
                }
            }

            # LicenseUri
            if (Enable-Metadata $buildInfo.ReleaseManifest -PropertyName LicenseUri) {
                Update-Metadata $buildInfo.ReleaseManifest -PropertyName LicenseUri -Value 'https://opensource.org/licenses/MIT'
            }

            # ProjectUri
            if (Enable-Metadata $buildInfo.ReleaseManifest -PropertyName ProjectUri) {
                # Attempt to parse the project URI from the list of upstream repositories
                [String]$pushOrigin = (git remote -v) -like 'origin*(push)'
                if ($pushOrigin -match 'origin\s+(?<ProjectUri>\S+).git') {
                    Update-Metadata $buildInfo.ReleaseManifest -PropertyName ProjectUri -Value $matches.ProjectUri
                }
            }
        } catch {
            throw
        }
    }
}