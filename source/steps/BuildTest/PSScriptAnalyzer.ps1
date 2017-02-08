function PSScriptAnalyzer {
    # Execute PSScriptAnalyzer against the module.

    [BuildStep('BuildTest')]
    param( )

    $i = 0

    foreach ($path in 'source\public', 'source\private', 'source\InitializeModule.ps1') {
        Invoke-ScriptAnalyzer -Path $path -Recurse | ForEach-Object {
            $i++
            
            $_
        }
    }
    if ($i -gt 0) {
        throw 'PSScriptAnalyzer tests are not clean'
    }
}