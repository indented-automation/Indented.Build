BuildTask PSScriptAnalyzer -Stage Test -Properties @{
    Order          = 1
    ValidWhen      = { $this.ReleaseType -ge 'Minor' -and (Get-Module PSScriptAnalyzer -ListAvailable) }
    Implementation = {
        $i = 0

        foreach ($directory in 'enumeration', 'class', 'private', 'public', 'InitializeModule.ps1') {
            $path = Join-Path $buildInfo.Source $directory
            if (Test-Path $path) {
                Invoke-ScriptAnalyzer -Path $path -Recurse | ForEach-Object {
                    $i++

                    $_
                }
            }
        }
        if ($i -gt 0) {
            throw 'PSScriptAnalyzer tests are not clean'
        }
    }
}