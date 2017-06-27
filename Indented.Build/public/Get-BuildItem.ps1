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

        # BuildInfo is used to determine the source path.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSTypeName('BuildInfo')]
        [PSObject]$BuildInfo,

        # Exclude script files containing PowerShell classes.
        [Switch]$ExcludeClass
    )

    Push-Location $buildInfo.Path.Source

    $itemTypes = @{
        enumeration    = 'enum*'
        class          = 'class*'
        private        = 'priv*'
        public         = 'pub*'
        initialisation = 'InitializeModule.ps1'
    }

    if ($Type -eq 'ShouldMerge') {
        foreach ($itemType in $itemTypes.Keys) {
            if ($itemType -ne 'class' -or ($itemType -eq 'class' -and -not $ExcludeClass)) {
                $items = Get-ChildItem $itemTypes[$itemType] -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { -not $_.PSIsContainer -and $_.Extension -eq '.ps1' -and $_.Length -gt 0 }

                $orderingFilePath = Join-Path $itemTypes[$itemType] 'order.txt'
                if (Test-Path $orderingFilePath) {
                    [String[]]$order = Get-Content (Resolve-Path $orderingFilePath).Path

                    $items = $items | Sort-Object {
                        $index = $order.IndexOf($_.BaseName)
                        if ($index -eq -1) {
                            [Int32]::MaxValue
                        } else {
                            $index
                        }
                    }, Name
                }

                $items
            }
        }
    } elseif ($Type -eq 'Static') {
        [String[]]$exclude = $itemTypes.Values + '*.config', 'test*', 'doc', 'help', '.build*.ps1'

        Get-ChildItem -Exclude $exclude
    }

    Pop-Location
}