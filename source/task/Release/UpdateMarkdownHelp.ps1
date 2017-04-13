BuildTask UpdateMarkdownHelp -Stage Release -Properties @{
    ValidWhen      = { Get-Module platyPS -ListAvailable }
    Implementation = {
        $exceptionMessage = powershell.exe -NoProfile -Command "
            try {
                Import-Module $($buildInfo.ReleaseManifest.FullName) -ErrorAction Stop
                New-MarkdownHelp -Module $($buildInfo.ModuleName) -OutputFolder '$($buildInfo.Source)\help'

                exit 0
            } catch {
                `$_.Exception.Message

                exit 1
            }
        "
        
        if ($lastexitcode -ne 0) {
            throw $exceptionMessage
        }

        Copy-Item (Join-Path $buildInfo.Source 'help') -Destination $buildInfo.Package -Recurse
    }
}