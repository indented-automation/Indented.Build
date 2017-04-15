BuildTask UpdateVersion -Stage Publish -Properties @{
    Order          = 0
    Implementation = {
        Update-Metadata (Join-Path $buildInfo.Source $buildInfo.ReleaseManifest.Name) -PropertyName ModuleVersion -Value $buildInfo.Version
    }
}