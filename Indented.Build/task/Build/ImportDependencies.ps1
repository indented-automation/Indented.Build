BuildTask ImportDependencies -Stage Build -Properties @{
    ValidWhen      = { Test-Path (Join-Path $buildInfo.Source 'modules.config') }
    Implementation = {
        $libPath = Join-Path $buildInfo.ModuleBase 'lib'
        if (-not (Test-Path $libPath)) {
            $null = New-Item $libPath -ItemType Directory
        }
        foreach ($module in ([Xml](Get-Content 'modules.config' -Raw)).modules.module) {
            Find-Module -Name $module.Name | Save-Module -Path $libPath
        }
    }
}