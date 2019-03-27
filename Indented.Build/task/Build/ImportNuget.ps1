BuildTask ImportDependencies -Stage Build -If {
    Test-Path (Join-Path $buildInfo.Path.Source.Module 'packages.config')
} -Definition {
    $path = Join-Path $buildInfo.Path.Build.Module 'lib'
    if (-not (Test-Path $path)) {
        $null = New-Item $path -ItemType Directory
    }

    $configPath = Join-Path $buildInfo.Path.Source.Module 'packages.config'
    foreach ($package in ([Xml](Get-Content $configPath -Raw)).packages.package) {
        Find-Package -Name $package.Name -RequiredVersion $package.Version
    }
}