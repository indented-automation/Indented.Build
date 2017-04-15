BuildTask TestSolution -Stage Test -Properties @{
    ValidWhen      = { (Test-Path (Join-Path $buildInfo.Source 'class\*.sln')) -and (Test-Path (Join-Path $buildInfo.Source 'class\packages\NUnit.ConsoleRunner.*\tools\nunit3-console.exe')) }
    Order          = 2
    Implementation = {
        Push-Location (Join-Path $buildInfo.Source 'class')

        $nunitConsole = (Resolve-Path 'packages\NUnit.ConsoleRunner.*\tools\nunit3-console.exe').Path
        Get-ChildItem -Filter *tests.dll -Recurse | Where-Object FullName -like '*bin*' | ForEach-Object {
            & $nunitConsole $_.FullName --result ('{0}\{1}.xml' -f $buildInfo.Output.FullName, ($_.Name -replace '\.tests'))
        }

        Pop-Location
    }
}