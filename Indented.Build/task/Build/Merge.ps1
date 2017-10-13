BuildTask Merge -Stage Build -Order 4 -Definition {
    $fileStream = [System.IO.File]::Create($buildInfo.Path.RootModule)
    $writer = New-Object System.IO.StreamWriter($fileStream)

    $usingStatements = New-Object System.Collections.Generic.List[String]

    $buildInfo | Get-BuildItem -Type ShouldMerge | ForEach-Object {
        $functionDefinition = Get-Content $_.FullName | ForEach-Object {
            if ($_ -match '^using (namespace|assembly)') {
                $usingStatements.Add($_)
            } else {
                $_.TrimEnd()
            }
        } | Out-String
        $writer.WriteLine($functionDefinition.Trim())
        $writer.WriteLine()
    }

    if (Test-Path 'InitializeModule.ps1') {
        $writer.WriteLine('InitializeModule')
    }

    $writer.Close()

    $rootModule = (Get-Content $buildInfo.Path.RootModule -Raw).Trim()
    if ($usingStatements.Count -gt 0) {
        # Add "using" statements to be start of the psm1
        $rootModule = $rootModule.Insert(0, "`r`n`r`n").Insert(
            0,
            (($usingStatements.ToArray() | Sort-Object | Get-Unique) -join "`r`n")
        )
    }
    Set-Content -Path $buildInfo.Path.RootModule -Value $rootModule -NoNewline
}