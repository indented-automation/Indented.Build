BuildTask TestSolution -Stage Test -If { Test-Path 'class*\packages\NUnit.ConsoleRunner.*\tools\nunit3-console.exe' } -Definition {
    Push-Location (Resolve-Path (Join-Path $buildInfo.Path.Source 'class*'))

    $nunitConsole = (Resolve-Path 'packages\NUnit.ConsoleRunner.*\tools\nunit3-console.exe').Path
    Get-ChildItem -Filter *tests.dll -Recurse | Where-Object FullName -like '*bin*' | ForEach-Object {
        & $nunitConsole $_.FullName --result ('{0}\{1}.xml' -f $buildInfo.Output.FullName, ($_.Name -replace '\.tests'))
    }

    Pop-Location
}