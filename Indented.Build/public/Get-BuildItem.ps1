function Get-BuildItem {
    <#
    .SYNOPSIS
        Get source items.
    .DESCRIPTION
        Get items from the source tree which will be consumed by the build process.

        This function centralises the logic required to enumerate files and folders within a project.
    #>

    [CmdletBinding()]
    [OutputType([System.IO.FileInfo], [System.IO.DirectoryInfo])]
    param (
        # Gets items by type.
        #
        #   ShouldMerge - *.ps1 files from enum*, class*, priv*, pub* and InitializeModule if present.
        #   Static      - Files which are not within a well known top-level folder. Captures help content in en-US, format files, configuration files, etc.
        [Parameter(Mandatory = $true)]
        [ValidateSet('ShouldMerge', 'Static')]
        [String]$Type,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSTypeName('BuildInfo')]
        [PSObject]$BuildInfo
    )

    Push-Location $buildInfo.Path.Source

    if ($Type -eq 'ShouldMerge') {
        $items = 'enum*', 'class*', 'priv*', 'pub*', 'InitializeModule.ps1'

        Get-ChildItem $items -Recurse -ErrorAction SilentlyContinue |
            Where-Object { -not $_.PSIsContainer -and $_.Extension -eq '.ps1' -and $_.Length -gt 0 }
    } elseif ($Type -eq 'Static') {
        $exclude = 'class*', 'enum*', 'priv*', 'pub*', 'InitializeModule.ps1', '*.config', 'test*', 'help', '.build*.ps1'

        Get-ChildItem -Exclude $exclude
    }

    Pop-Location
}