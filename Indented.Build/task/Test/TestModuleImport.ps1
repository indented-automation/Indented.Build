BuildTask TestModuleImport -Stage Test -Properties @{
    Order          = 0
    Implementation = {
        $exceptionMessage = powershell.exe -NoProfile -Command "
            try {
                Import-Module '$($buildInfo.ReleaseManifest.FullName)' -ErrorAction Stop

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