BuildTask PSScriptAnalyzer -Stage Test -Properties @{
    Order          = 1
    ValidWhen      = { Get-Module PSScriptAnalyzer -ListAvailable }
    Implementation = {
        'enumeration', 'class', 'private', 'public', 'InitializeModule.ps1' | ForEach-Object {
            $path = Join-Path $buildInfo.Source $_
            if (Test-Path $path) {
                Invoke-ScriptAnalyzer -Path $path -Recurse | ForEach-Object {
                    $_
                    $_ | Export-Csv (Join-Path $buildInfo.Output 'psscriptanalyzer.csv') -NoTypeInformation -Append
                }
            }
        }
    }
}