BuildTask PSScriptAnalyzer -Stage Test -Properties @{
    ValidWhen      = { $this.ReleaseType -ge 'Minor' -and (Get-Module PSScriptAnalyzer -ListAvailable) }
    Implementation = {
        $i = 0

        foreach ($path in 'public', 'private', 'InitializeModule.ps1') {
            Invoke-ScriptAnalyzer -Path $path -Recurse | ForEach-Object {
                $i++
                
                $_
            }
        }
        if ($i -gt 0) {
            throw 'PSScriptAnalyzer tests are not clean'
        }
    }
}