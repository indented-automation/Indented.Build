BuildTask ImportDependencies -Stage Build -If {
    Test-Path (Join-Path $buildInfo.Path.Source.Module 'modules.config')
} -Definition {
    # Allows modules to be nested within the current module.

    $path = Join-Path $buildInfo.Path.Build.Module 'lib'
    if (-not (Test-Path $path)) {
        $null = New-Item $path -ItemType Directory
    }

    $configPath = Join-Path $buildInfo.Path.Source.Module 'modules.config'
    foreach ($module in ([Xml](Get-Content $configPath -Raw)).modules.module) {
        Find-Module -Name $module.Name | Save-Module -Path $path
    }
}