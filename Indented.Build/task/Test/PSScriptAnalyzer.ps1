BuildTask PSScriptAnalyzer -Stage Test -Order 1 -If { Get-Module PSScriptAnalyzer -ListAvailable } -Definition {
    'enumeration', 'class', 'private', 'public', 'InitializeModule.ps1' | ForEach-Object {
        $path = Join-Path $buildInfo.Path.Source $_
        if (Test-Path $path) {
            Invoke-ScriptAnalyzer -Path $path -Recurse | ForEach-Object {
                $_
                $_ | Export-Csv (Join-Path $buildInfo.Path.Output 'psscriptanalyzer.csv') -NoTypeInformation -Append
            }
        }
    }
}