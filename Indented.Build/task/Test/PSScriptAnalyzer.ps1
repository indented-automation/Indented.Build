BuildTask PSScriptAnalyzer -Stage Test -Order 2 -Definition {
    # Invoke PSScriptAnalyzer tests.

    try {
        Invoke-ScriptAnalyzer -Path $buildInfo.Path.Build.RootModule |
            Select-Object RuleName, Severity, Line, Message
    } catch {
        throw
    } finally {
        Pop-Location
    }
}