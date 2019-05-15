BuildTask TestSolution -Stage Test -If {
    Test-Path (Join-Path $buildInfo.Path.Source.Module 'class*\packages\NUnit.ConsoleRunner.*\tools\nunit3-console.exe')
} -Definition {
    # If a visual studio solution is present, and nunit-console has been restored by nuget, execute unit tests.

    Push-Location (Resolve-Path (Join-Path $buildInfo.Path.Source.Module 'class*'))

    $nunitConsole = (Resolve-Path 'packages\NUnit.ConsoleRunner.*\tools\nunit3-console.exe').Path
    Get-ChildItem -Filter *tests.dll -Recurse | Where-Object FullName -like '*bin*' | ForEach-Object {
        & $nunitConsole $_.FullName --result ('{0}\{1}.xml' -f $buildInfo.Build.Output.FullName, ($_.Name -replace '\.tests'))
    }

    Pop-Location
}