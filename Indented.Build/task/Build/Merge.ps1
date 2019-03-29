BuildTask Merge -Stage Build -Order 4 -Definition {
    # Merges module content into a single psm1 file.

    $writer = [System.IO.StreamWriter][System.IO.File]::Create($buildInfo.Path.Build.RootModule)

    $usingStatements = [System.Collections.Generic.HashSet[String]]::new()

    $buildInfo | Get-BuildItem -Type ShouldMerge | ForEach-Object {
        $functionDefinition = Get-Content $_.FullName | ForEach-Object {
            if ($_ -match '^using (namespace|assembly)') {
                $null = $usingStatements.Add($_)
            } else {
                $_.TrimEnd()
            }
        }
        $writer.Write(($functionDefinition -join $buildInfo.Config.EndOfLineChar).Trim())
        $writer.Write($buildInfo.Config.EndOfLineChar * 2)
    }

    if (Test-Path (Join-Path $buildInfo.Path.Source.Module 'InitializeModule.ps1')) {
        $writer.WriteLine('InitializeModule')
    }

    $writer.Close()

    $rootModule = (Get-Content $buildInfo.Path.Build.RootModule -Raw).Trim()
    if ($usingStatements.Count -gt 0) {
        # Add "using" statements to be start of the psm1
        $rootModule = $rootModule.Insert(
            0,
            ($buildInfo.Config.EndOfLineChar * 2)
        ).Insert(
            0,
            (($usingStatements | Sort-Object) -join $buildInfo.Config.EndOfLineChar)
        )
    }
    Set-Content -Path $buildInfo.Path.Build.RootModule -Value $rootModule -NoNewline
}