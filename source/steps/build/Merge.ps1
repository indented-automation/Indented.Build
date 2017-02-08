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
    
    [BuildStep('Build')]
    param( )

    $mergeItems = 'enumerations', 'classes', 'private', 'public', 'InitializeModule.ps1'

    Get-ChildItem 'source' -Exclude $mergeItems |
        Copy-Item -Destination $buildInfo.ModuleBase -Recurse

    $fileStream = [System.IO.File]::Create($buildInfo.RootModule)
    $writer = New-Object System.IO.StreamWriter($fileStream)

    $usingStatements = New-Object System.Collections.Generic.List[String]

    foreach ($item in $mergeItems) {
        $path = Join-Path 'source' $item

        Get-ChildItem $path -Filter *.ps1 -File -Recurse |
            Where-Object { $_.Extension -eq '.ps1' -and $_.Length -gt 0 } |
            ForEach-Object {
                $functionDefinition = Get-Content $_.FullName | ForEach-Object {
                    if ($_ -match '^using') {
                        $usingStatements.Add($_)
                    } else {
                        $_.TrimEnd()
                    }
                } | Out-String
                $writer.WriteLine($functionDefinition.Trim())
                $writer.WriteLine()
            }
    }

    if (Test-Path 'source\InitializeModule.ps1') {
        $writer.WriteLine('InitializeModule')
    }

    $writer.Close()

    $rootModule = (Get-Content $buildInfo.RootModule -Raw).Trim()
    if ($usingStatements.Count -gt 0) {
        $rootModule = $rootModule.Insert(0, "`r`n`r`n").Insert(
            0,
            (($usingStatements.ToArray() | Sort-Object | Get-Unique) -join "`r`n")
        )
    }
    Set-Content -Path $buildInfo.RootModule -Value $rootModule -NoNewline
}