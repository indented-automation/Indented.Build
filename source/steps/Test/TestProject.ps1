BuildTask TestProject -Stage Test -Properties @{
    ValidWhen = { (Test-Path 'source\classes\*.sln') -and (Test-Path 'classes\packages\NUnit.ConsoleRunner.*\tools\nunit3-console.exe') }
    Implementation = {
        $nunitConsole = (Resolve-Path $path).Path
        Get-ChildItem 'source\classes' -Filter *tests.dll -Recurse | Where-Object FullName -like '*bin*' | ForEach-Object {
            & $nunitConsole $_.FullName --result ('{0}\{1}.xml' -f $buildInfo.Output.FullName, ($_.Name -replace '\.tests'))

            if ($lastexitcode -ne 0) {
                throw 'VS unit tests failed'
            }
        }
    }
}