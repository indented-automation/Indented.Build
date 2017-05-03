BuildTask TestModuleImport -Stage Test -Order 0 -Definition {
    $exceptionMessage = powershell.exe -NoProfile -Command "
        try {
            Import-Module '$($buildInfo.Path.Manifest.FullName)' -ErrorAction Stop

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