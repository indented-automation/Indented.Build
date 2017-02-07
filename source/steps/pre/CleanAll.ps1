function Clean {
    # .SYNOPSIS
    #   Clean all content from the build directory.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     01/02/2017 - Chris Dent - Added help.

    if (Get-GitDirectory) {
        $path = Join-Path (Get-GitDirectory) 'build'
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force
        }
        $null = New-Item $path -ItemType Directory -Force
    }
}