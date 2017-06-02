BuildTask UpdateMetadata -Stage Build -Definition {
    try {
        $path = $buildInfo.Path.Manifest

        # Version
        Update-Metadata $path -PropertyName ModuleVersion -Value $buildInfo.Version
        
        # RootModule
        if (Enable-Metadata $path -PropertyName RootModule) {
            Update-Metadata $path -PropertyName RootModule -Value $buildInfo.Path.RootModule.Name
        }

        # FunctionsToExport
        if (Enable-Metadata $path -PropertyName FunctionsToExport) {
            Update-Metadata $path -PropertyName FunctionsToExport -Value (
                (Get-ChildItem (Join-Path $buildInfo.Path.Source 'pub*') -Filter '*.ps1' -Recurse).BaseName
            )
        }

        # RequiredAssemblies
        if (Test-Path (Join-Path $buildInfo.Path.Package 'lib\*.dll')) {
            if (Enable-Metadata $path -PropertyName RequiredAssemblies) {
                Update-Metadata $path -PropertyName RequiredAssemblies -Value (
                    (Get-Item (Join-Path $buildInfo.Path.Package 'lib\*.dll')).Name | ForEach-Object {
                        Join-Path 'lib' $_
                    }
                )
            }
        }

        # FormatsToProcess
        if (Test-Path (Join-Path $buildInfo.Path.Package '*.Format.ps1xml')) {
            if (Enable-Metadata $path -PropertyName FormatsToProcess) {
                Update-Metadata $path -PropertyName FormatsToProcess -Value (Get-Item (Join-Path $buildInfo.Path.Package '*.Format.ps1xml')).Name
            }
        }

        # LicenseUri
        if (Test-Path (Join-Path $buildInfo.Path.ProjectRoot 'LICENSE')) {
            if (Enable-Metadata $path -PropertyName LicenseUri) {
                Update-Metadata $path -PropertyName LicenseUri -Value 'https://opensource.org/licenses/MIT'
            }
        }

        # ProjectUri
        if (Enable-Metadata $path -PropertyName ProjectUri) {
            # Attempt to parse the project URI from the list of upstream repositories
            [String]$pushOrigin = (git remote -v) -like 'origin*(push)'
            if ($pushOrigin -match 'origin\s+(?<ProjectUri>\S+).git') {
                Update-Metadata $path -PropertyName ProjectUri -Value $matches.ProjectUri
            }
        }
    } catch {
        throw
    }
}