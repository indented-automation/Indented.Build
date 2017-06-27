task CreateNupkg {
    $path = Join-Path $buildInfo.Path.Output 'pack'

    # Add module content
    Copy-Item $buildInfo.Path.Package.Parent.FullName -Destination $path -Recurse
    $null = New-Item (Join-Path $path 'tools') -ItemType Directory
    # Create a generic install script
    'Copy-Item "$psscriptroot\..\{0}" -Destination "$env:PROGRAMFILES\WindowsPowerShell\Modules" -Recurse -Force' -f $buildInfo.ModuleName |
        Out-File (Join-Path $path 'tools\install.ps1')
    # Create deploy.ps1 for Octopus Deploy
    '& "$psscriptroot\tools\install.ps1"' | Out-File (Join-Path $path 'deploy.ps1')
    # Create chocolateyInstall.ps1
    '& "$psscriptroot\install.ps1"' | Out-File (Join-Path $path 'tools\chocolateyInstall.ps1')

    Push-Location $path

    nuget pack -OutputDirectory $buildInfo.Path.Output

    Pop-Location
}