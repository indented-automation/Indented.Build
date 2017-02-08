function Update-BuildScript {
    # .SYNOPSIS
    #   Update an existing build script.
    # .DESCRIPTION
    #   Update an existing build script based on the template.
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
        [String]$Path
    )

    if (Test-Path $Path) {
        if ((Get-Command $Path).Parameters.ContainsKey('GetBuildInfo')) {
            $steps = (& $Path -GetBuildInfo).GetSteps()

            Copy-Item "$psscriptroot\var\skel\build.ps1" $path -Force

            foreach ($step in $steps) {
                (& $Path -GetBuildInfo).AddStep($step.Name)
            }
        } else {
            Copy-Item "$psscriptroot\var\skel\build.ps1" $path -Force
        }
    } else {
        Copy-Item "$psscriptroot\var\skel\build.ps1" $path -Force
    }
}