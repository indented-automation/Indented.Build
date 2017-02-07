function Clean {
    # .SYNOPSIS
    #   Clean the last build of this module from the build directory.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     01/02/2017 - Chris Dent - Added help.

    if (Get-Module $buildInfo.ModuleName) {
        Remove-Module $buildInfo.ModuleName
    }

    if (Test-Path $buildInfo.BuildPath) {
        Remove-Item $buildInfo.BuildPath -Recurse -Force
    }
    $null = New-Item $buildInfo.BuildPath -ItemType Directory -Force
}