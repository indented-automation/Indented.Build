function Clean {
    # .SYNOPSIS
    #   Clean the last build of this module from the build directory.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     01/02/2017 - Chris Dent - Added help.

    [BuildStep('Build', Order = 0)]
    param( )

    if (Get-Module $buildInfo.ModuleName) {
        Remove-Module $buildInfo.ModuleName
    }

    Get-ChildItem -Directory |
        Where-Object { [Version]::TryParse($_.Name, [Ref]$null) } |
        Remove-Item -Recurse -Force
    if (Test-Path $buildInfo.Output) {
        Remove-Item $buildInfo.Output -Recurse -Force
    }

    $null = New-Item $buildInfo.Output -ItemType Directory -Force
    $null = New-Item $buildInfo.ModuleBase -ItemType Directory -Force
}