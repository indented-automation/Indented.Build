BuildTask CopyModuleFiles -Stage Build -Properties @{
    Order          = 3
    Implementation = {
        $exclude = 'class', 'enumeration', 'private', 'public', 'InitializeModule.ps1', 'modules.config', 'packages.config', 'test'

        Get-ChildItem $buildInfo.Source -Exclude $exclude |
            Copy-Item -Destination $buildInfo.Package -Recurse -Force
    }
}