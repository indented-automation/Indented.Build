BuildTask InstallRequiredModules -Stage Setup -Order 1 -Definition {
    $erroractionpreference = 'Stop'
    try {
        $nugetPackageProvider = Get-PackageProvider NuGet -ErrorAction SilentlyContinue
        if (-not $nugetPackageProvider -or $nugetPackageProvider.Version -lt [Version]'2.8.5.201') {
            $null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        }
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

        'Configuration', 'Pester' | Where-Object { -not (Get-Module $_ -ListAvailable) } | ForEach-Object {
            Install-Module $_ -Scope CurrentUser
        }
        Import-Module 'Configuration', 'Pester' -Global
    } catch {
        throw
    }
}