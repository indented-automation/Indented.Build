BuildTask UpdateVersion -Stage Release -Properties @{
    Implementation = {
        Update-Metadata $buildInfo.Manifest -PropertyName ModuleVersion -Value $buildInfo.Version
        Update-Metadata (Join-Path 'source' $buildInfo.Manifest.Name) -PropertyName ModuleVersion -Value $buildInfo.Version
    }
}