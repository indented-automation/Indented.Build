using namespace System.IO

function GetProjectRoot {
    <#
    .SYNOPSIS
        Get the root of the current repository.
    .DESCRIPTION
        GetProjectRoot supports Git repositories and returns the root of the repository.
    #>
    
    [OutputType([System.IO.DirectoryInfo])]
    param ( )

    if ($projectRoot = (git rev-parse --show-toplevel 2> $null)) {
        return Get-Item $projectRoot
    }
    throw New-Object InvalidOperationException('Unable to discover repository root')
}