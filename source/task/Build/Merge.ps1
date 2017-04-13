BuildTask Merge -Stage Build -Properties @{
    Implementation = {
        $fileStream = [System.IO.File]::Create($buildInfo.RootModule)
        $writer = New-Object System.IO.StreamWriter($fileStream)

        $usingStatements = New-Object System.Collections.Generic.List[String]

        Get-ChildItem $mergeItems -Filter *.ps1 -File -Recurse -ErrorAction SilentlyContinue |
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

        if (Test-Path 'InitializeModule.ps1') {
            $writer.WriteLine('InitializeModule')
        }

        $writer.Close()

        $rootModule = (Get-Content $buildInfo.RootModule -Raw).Trim()
        if ($usingStatements.Count -gt 0) {
            # Add "using" statements to be start of the psm1
            $rootModule = $rootModule.Insert(0, "`n`n").Insert(
                0,
                (($usingStatements.ToArray() | Sort-Object | Get-Unique) -join "`n")
            )
        }
        Set-Content -Path $buildInfo.RootModule -Value $rootModule -NoNewline
    }
}