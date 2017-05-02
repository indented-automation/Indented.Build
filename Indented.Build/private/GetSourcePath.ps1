function GetSourcePath {
    <#
    .SYNOPSIS
        Get the path to build.
    .DESCRIPTION
        Get the path to the folder containing the article(s) to build.
    #>

    [OutputType([System.IO.DirectoryInfo])]
    param (
        [Parameter(Mandatory = $true)]
        [DirectoryInfo]$ProjectRoot
    )

    if (Test-Path (Join-Path $ProjectRoot 'source')) {
        return Join-Path $ProjectRoot 'source'
    } elseif (Test-Path 'source') {
        return Join-Path $pwd 'source'
    } elseif ((Split-Path $pwd -Leaf) -eq 'source') {
        return $pwd.Path
    } elseif ((Test-Path '*.psd1') -and ((Get-Item '*.psd1').BaseName -eq (Get-Item $pwd).Name)) {
        return $pwd.Path
    } elseif (Test-Path (Join-Path $ProjectRoot $ProjectRoot.Name)) {
        return Join-Path $ProjectRoot $ProjectRoot.Name
    }

    throw 'Unable to determine the source path'
}