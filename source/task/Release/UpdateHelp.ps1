BuildTask UpdateHelp -Stage Release -Properties @{
    ValidWhen      = { Get-Module platyPS -ListAvailable }
    Implementation = {
        $exceptionMessage = powershell.exe -NoProfile -Command "
            try {
                Import-Module $($buildInfo.ReleaseManifest.FullName) -ErrorAction Stop
                New-MarkdownHelp -Module $($buildInfo.ModuleName) -OutputFolder '$($buildInfo.Package)\doc'

                exit 0
            } catch {
                `$_.Exception.Message

                exit 1
            }
        "
        
        if ($lastexitcode -ne 0) {
            throw $exceptionMessage
        }
    }
}