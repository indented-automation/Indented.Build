BuildTask PSScriptAnalyzer -Stage Test -Order 1 -If {
    Get-Module PSScriptAnalyzer -ListAvailable
} -Definition {
    try {
        Push-Location $buildInfo.Path.Source.Module
        'priv*', 'pub*', 'InitializeModule.ps1' | Where-Object { Test-Path $_ } | ForEach-Object {
            $path = Resolve-Path (Join-Path $buildInfo.Path.Source.Module $_)
            if (Test-Path $path) {
                Invoke-ScriptAnalyzer -Path $path -Recurse | ForEach-Object {
                    $_ | Select-Object RuleName, Severity, Line, Message, ScriptName, ScriptPath
                    $_ | Export-Csv (Join-Path $buildInfo.Path.Build.Output 'psscriptanalyzer.csv') -NoTypeInformation -Append
                }
            }
        }
    } catch {
        throw
    } finally {
        Pop-Location
    }
}