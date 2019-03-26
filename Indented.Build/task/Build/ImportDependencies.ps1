BuildTask ImportDependencies -Stage Build -If {
    Test-Path (Join-Path $buildInfo.Path.Source.Module 'modules.config')
} -Definition {
    $path = Join-Path $buildInfo.Path.Build.Module 'lib'
    if (-not (Test-Path $path)) {
        $null = New-Item $path -ItemType Directory
    }
    foreach ($module in ([Xml](Get-Content 'modules.config' -Raw)).modules.module) {
        Find-Module -Name $module.Name | Save-Module -Path $path
    }
}