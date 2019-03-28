BuildTask InstallRequiredModules -Stage Setup -Order 1 -Definition {
    $erroractionpreference = 'Stop'
    try {
        Update-Module PSDepend -Scope CurrentUser
        Invoke-PSDepend -InputObject @{
            PSDependsOptions = @{
                Target    = $buildInfo.Path.Build.Modules
                AddToPath = $true
            }

            Configuration    = 'latest'
            Pester           = 'latest'
            PlatyPS          = 'latest'
            PSScriptAnalyzer = 'latest'
            PSCodeHealth     = 'latest'
        }
    } catch {
        throw
    }
}