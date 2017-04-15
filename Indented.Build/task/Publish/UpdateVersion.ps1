BuildTask UpdateVersion -Stage Publish -Properties @{
    Order          = 0
    Implementation = {
        Update-Metadata (Join-Path 'source' $buildInfo.Manifest.Name) -PropertyName ModuleVersion -Value $buildInfo.Version
    }
}