BuildTask PSScriptAnalyzer -If { Get-Module PSScriptAnalyzer -ListAvailable } -Stage Test -Order 1 -Definition {
    try {
        Push-Location $buildInfo.Path.Source
        'priv*', 'pub*', 'InitializeModule.ps1' | Where-Object { Test-Path $_ } | ForEach-Object {
            $path = Resolve-Path (Join-Path $buildInfo.Path.Source $_)
            if (Test-Path $path) {
                Invoke-ScriptAnalyzer -Path $path -Recurse | ForEach-Object {
                    $_
                    $_ | Export-Csv (Join-Path $buildInfo.Path.Output 'psscriptanalyzer.csv') -NoTypeInformation -Append
                }
            }
        }
    } catch {
        throw
    } finally {
        Pop-Location
    }
}