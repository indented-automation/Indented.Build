BuildTask TestSolution -Stage Test -Properties @{
    ValidWhen = { (Test-Path 'class\*.sln') -and (Test-Path 'class\packages\NUnit.ConsoleRunner.*\tools\nunit3-console.exe') }
    Implementation = {
        $nunitConsole = (Resolve-Path 'class\packages\NUnit.ConsoleRunner.*\tools\nunit3-console.exe').Path
        Get-ChildItem 'class' -Filter *tests.dll -Recurse | Where-Object FullName -like '*bin*' | ForEach-Object {
            & $nunitConsole $_.FullName --result ('{0}\{1}.xml' -f $buildInfo.Output.FullName, ($_.Name -replace '\.tests'))

            if ($lastexitcode -ne 0) {
                throw 'Solution unit tests failed'
            }
        }
    }
}