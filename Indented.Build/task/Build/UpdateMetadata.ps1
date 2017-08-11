BuildTask UpdateMetadata -Stage Build -Order 5 -Definition {
    try {
        $path = $buildInfo.Path.Manifest

        # Version
        Update-Metadata $path -PropertyName ModuleVersion -Value $buildInfo.Version
        
        # RootModule
        if (Enable-Metadata $path -PropertyName RootModule) {
            Update-Metadata $path -PropertyName RootModule -Value $buildInfo.Path.RootModule.Name
        }

        # FunctionsToExport
        $functionsToExport = (Get-ChildItem (Join-Path $buildInfo.Path.Source 'pub*') -Filter '*.ps1' -Recurse)
        if ($functionsToExport) {
            if (Enable-Metadata $path -PropertyName FunctionsToExport) {
                Update-Metadata $path -PropertyName FunctionsToExport -Value $functionsToExport.BaseName
            }
        }

        # DscResourcesToExport
        $tokens = $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            (Get-Content $buildInfo.Path.RootModule -Raw),
            $buildInfo.Path.RootModule,
            [Ref]$tokens,
            [Ref]$parseErrors
        )
        $dscResourcesToExport = $ast.FindAll( {
            param ($ast)

            $ast -is [System.Management.Automation.Language.TypeDefinitionAst] -and 
            $ast.IsClass -and 
            $ast.Attributes.TypeName.FullName -contains 'DscResource'
        }, $true).Name
        if ($null -ne $dscResourcesToExport) {
            if (Enable-Metadata $path -PropertyName DscResourcesToExport) {
                Update-Metadata $path -PropertyName DscResourcesToExport -Value $dscResourcesToExport
            }
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