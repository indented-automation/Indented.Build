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

    $path = Join-Path $buildInfo.BuildPath $buildInfo.Manifest

    # RootModule
    if (Enable-Metadata $path -PropertyName RootModule) {
        Update-Metadata $path -PropertyName RootModule -Value $buildInfo.RootModule
    }

    # FunctionsToExport
    if (Enable-Metadata $path -PropertyName FunctionsToExport) {
        Update-Metadata $path -PropertyName FunctionsToExport -Value (
            (Get-ChildItem 'source\public' -Filter '*.ps1' -File -Recurse).BaseName
        )
    }

    # RequiredAssemblies
    if (Test-Path 'build\package\libraries\*.dll') {
        if (Enable-Metadata $path -PropertyName RequiredAssemblies) {
            Update-Metadata $path -PropertyName RequiredAssemblies -Value (
                (Get-Item 'build\package\libraries\*.dll').Name | ForEach-Object {
                    Join-Path 'libraries' $_
                }
            )
        }
    }

    # FormatsToProcess
    if (Test-Path 'build\package\*.Format.ps1xml') {
        if (Enable-Metadata $path -PropertyName FormatsToProcess) {
            Update-Metadata $path -PropertyName FormatsToProcess -Value (Get-Item 'build\package\*.Format.ps1xml').Name
        }
    }

    # LicenseUri
    if (Enable-Metadata $path -PropertyName LicenseUri) {
        Update-Metadata $path -PropertyName LicenseUri -Value 'https://opensource.org/licenses/MIT'
    }

    # ProjectUri
    if (Enable-Metadata $path -PropertyName ProjectUri) {
        # Attempt to parse the project URI from the list of upstream repositories
        [String]$pushOrigin = (git remote -v) -like 'origin*(push)'
        if ($pushOrigin -match 'origin\s+(?<ProjectUri>\S+).git') {
            Update-Metadata $path -PropertyName ProjectUri -Value $matches.ProjectUri
        }
    }

    # Update-Metadata adds empty lines. Work-around to clean up all versions of the file.
    $content = (Get-Content $path -Raw).TrimEnd()
    Set-Content $path -Value $content

    $content = (Get-Content "source\$($buildInfo.Manifest)" -Raw).TrimEnd()
    Set-Content "source\$($buildInfo.Manifest)" -Value $content
}