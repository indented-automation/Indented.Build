function Add-BuildStep {
    # .SYNOPSIS
    #   Add a build step to an existing build script.
    # .DESCRIPTION
    #   Add a build step to an existing build script.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     08/02/2017 - Chris Dent - Created.

    [CmdletBinding()]
    param(
        # The path to a build script.
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [String]$Path,
        
        # The step to inject.
        [String[]]$StepName
    )

    if ((Get-Command $Path).Parameters.ContainsKey('GetBuildInfo')) {
        foreach ($name in $StepName) {
            (& $Path -GetBuildInfo).AddStep($name)
        }
    } else {
        throw 'Incompatible build script'
    }
}