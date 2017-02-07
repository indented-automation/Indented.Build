function Merge {
    # .SYNOPSIS
    #   Merge source files into a module.
    # .DESCRIPTION
    #   Merge the files which represent a module in development into a single psm1 file.
    #
    #   If an InitializeModule script (containing an InitializeModule function) is present it will be called at the end of the .psm1.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     01/02/2017 - Chris Dent - Added help.
    
    $path = Join-Path $buildInfo.BuildPath $buildInfo.RootModule

    Get-ChildItem 'source' -Exclude 'public', 'private', 'InitializeModule.ps1' |
        Copy-Item -Destination build\package -Recurse 

    $fileStream = New-Object System.IO.FileStream($path, 'Create')
    $writer = New-Object System.IO.StreamWriter($fileStream)

    Get-ChildItem 'source\public', 'source\private', 'InitializeModule.ps1' -Filter *.ps1 -File -Recurse | Where-Object Extension -eq '.ps1' | ForEach-Object {
        Get-Content $_.FullName | ForEach-Object {
            $writer.WriteLine($_.TrimEnd())
        }
        $writer.WriteLine()
    }

    if (Test-Path 'source\InitializeModule.ps1') {
        $writer.WriteLine('InitializeModule')
    }

    $writer.Close()
    $fileStream.Close()
}
