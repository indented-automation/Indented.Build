BuildTask UpdateVersion -Stage Publish -Order 0 -Definition {
    Update-Metadata (Join-Path $buildInfo.Path.Source $buildInfo.Path.Manifest.Name) -PropertyName ModuleVersion -Value $buildInfo.Version
}