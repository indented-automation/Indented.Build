function PSScriptAnalyzer {
    # Execute PSScriptAnalyzer against the module.

    $i = 0

    Get-ChildItem 'source\public', 'source\private', 'InitializeModule.ps1' -Filter *.ps1 -File -Recurse | Where-Object Extension -eq '.ps1' | ForEach-Object {
        Invoke-ScriptAnalyzer -Path $_.FullName | ForEach-Object {
            $i++
            
            $_
        }
    }
    if ($i -gt 0) {
        throw 'PSScriptAnalyzer tests are not clean'
    }
}