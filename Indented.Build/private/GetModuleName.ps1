function GetModuleName {
    <#
    .SYNOPSIS
        Get the name of the module to build.
    .DESCRIPTION
        Attempt to determine the name of the module to build from the Source path.
        
        The name of the module is updated to exactly match the name of a directory.
    #>

    [OutputType([String])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ } )]
        [System.IO.DirectoryInfo]$Source
    )

    if ($Source.Name -like 's*rc*') {
        return $Source.Parent.Parent.GetDirectories($Source.Parent.Name).Name
    } else {
        return $Source.Parent.GetDirectories($Source.Name).Name
    }
}