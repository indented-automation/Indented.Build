function Get-ChildBuildInfo {
    <#
    .SYNOPSIS
        Get items which can be built from child paths of the specified folder.
    .DESCRIPTION
        A folder may contain one or more items which can be built, this command may be used to discover individual projects.
    #>

    [CmdletBinding()]
    [OutputType('BuildInfo')]
    param (
        # The starting point for the build search.
        [String]$Path = $pwd.Path,

        # Recurse to the specified depth when attempting to find projects which can be built.
        [Int32]$Depth = 4
    )

    Get-ChildItem $Path -Filter *.psd1 -File -Depth $Depth | Where-Object { $_.BaseName -eq $_.Directory.Name } | ForEach-Object {
        $currentPath = $_.Directory.FullName
        try {
            Get-BuildInfo -Path $currentPath
        } catch {
            Write-Debug ('{0}: {1}' -f $currentPath, $_.Exception.Message)
        }
    }
}