task CreateNupkg {
    $path = Join-Path $buildInfo.Path.Output 'pack'

    # Add module content
    $null = New-Item $path -ItemType Directory -Force
    $null = New-Item (Join-Path $path 'tools') -ItemType Directory
    Copy-Item $buildInfo.Path.Package.Parent.Fullname -Destination (Join-Path $path 'tools') -Recurse

    # Create a generic install script
    $destination = '"$env:PROGRAMFILES\WindowsPowerShell\Modules\{0}"' -f $buildInfo.ModuleName
    @(
        'if (Test-Path {0}) {{' -f $destination
        '    Remove-Item {0} -Recurse' -f $destination
        '}'
        'Copy-Item "$psscriptroot\{0}" -Destination {1} -Recurse -Force' -f $buildInfo.ModuleName, $destination
    ) | Out-File (Join-Path $path 'tools\install.ps1') -Encoding UTF8

    # deploy.ps1 for Octopus Deploy
    '& "$psscriptroot\tools\install.ps1"' | Out-File (Join-Path $path 'deploy.ps1') -Encoding UTF8

    # chocolateyInstall.ps1
    '& "$psscriptroot\install.ps1"' | Out-File (Join-Path $path 'tools\chocolateyInstall.ps1') -Encoding UTF8

    Push-Location $path

    nuget pack -OutputDirectory $buildInfo.Path.Nuget

    Pop-Location
}