BuildTask InstallRequiredModules -Stage Setup -Order 1 -Definition {
    # Installs the modules required to execute the tasks in this script into current user scope.

    $erroractionpreference = 'Stop'
    try {
        if (Get-Module PSDepend -ListAvailable) {
            Update-Module PSDepend -ErrorAction SilentlyContinue
        } else {
            Install-Module PSDepend -Scope CurrentUser
        }
        Invoke-PSDepend -Install -Import -Force -InputObject @{
            PSDependOptions = @{
                Target    = 'CurrentUser'
            }

            Configuration    = 'latest'
            Pester           = 'latest'
            PlatyPS          = 'latest'
            PSScriptAnalyzer = 'latest'
        }
    } catch {
        throw
    }
}