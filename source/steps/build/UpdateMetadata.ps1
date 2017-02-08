function UpdateMetadata {
    # .SYNOPSIS
    #   Update the module manifest.
    # .DESCRIPTION
    #   Update the module manifest with:
    #
    #     * RootModule
    #     * FunctionsToExport
    #     * RequiredAssemblies
    #     * FormatsToProcess
    #     * LicenseUri
    #     * ProjectUri
    #
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     01/02/2017 - Chris Dent - Added help.

    [BuildStep('Build')]
    param( )

    # Version
    Update-Metadata $buildInfo.Manifest -PropertyName ModuleVersion -Value $buildInfo.Version
    Update-Metadata (Join-Path 'source' $buildInfo.Manifest.Name) -PropertyName ModuleVersion -Value $buildInfo.Version


    # RootModule
    if (Enable-Metadata $buildInfo.Manifest -PropertyName RootModule) {
        Update-Metadata $buildInfo.Manifest -PropertyName RootModule -Value $buildInfo.RootModule.Name
    }

    # FunctionsToExport
    if (Enable-Metadata $buildInfo.Manifest -PropertyName FunctionsToExport) {
        Update-Metadata $buildInfo.Manifest -PropertyName FunctionsToExport -Value (
            (Get-ChildItem 'source\public' -Filter '*.ps1' -File -Recurse).BaseName
        )
    }

    # RequiredAssemblies
    if (Test-Path 'build\package\libraries\*.dll') {
        if (Enable-Metadata $buildInfo.Manifest -PropertyName RequiredAssemblies) {
            Update-Metadata $buildInfo.Manifest -PropertyName RequiredAssemblies -Value (
                (Get-Item 'build\package\libraries\*.dll').Name | ForEach-Object {
                    Join-Path 'libraries' $_
                }
            )
        }
    }

    # FormatsToProcess
    if (Test-Path 'build\package\*.Format.ps1xml') {
        if (Enable-Metadata $buildInfo.Manifest -PropertyName FormatsToProcess) {
            Update-Metadata $buildInfo.Manifest -PropertyName FormatsToProcess -Value (Get-Item 'build\package\*.Format.ps1xml').Name
        }
    }

    # LicenseUri
    if (Enable-Metadata $buildInfo.Manifest -PropertyName LicenseUri) {
        Update-Metadata $buildInfo.Manifest -PropertyName LicenseUri -Value 'https://opensource.org/licenses/MIT'
    }

    # ProjectUri
    if (Enable-Metadata $buildInfo.Manifest -PropertyName ProjectUri) {
        # Attempt to parse the project URI from the list of upstream repositories
        [String]$pushOrigin = (git remote -v) -like 'origin*(push)'
        if ($pushOrigin -match 'origin\s+(?<ProjectUri>\S+).git') {
            Update-Metadata $buildInfo.Manifest -PropertyName ProjectUri -Value $matches.ProjectUri
        }
    }

    # Update-Metadata adds empty lines. Work-around to clean up all versions of the file.
    $content = (Get-Content $buildInfo.Manifest -Raw).TrimEnd()
    Set-Content $buildInfo.Manifest -Value $content

    $content = (Get-Content "source\$($buildInfo.Manifest.Name)" -Raw).TrimEnd()
    Set-Content "source\$($buildInfo.Manifest.Name)" -Value $content
}