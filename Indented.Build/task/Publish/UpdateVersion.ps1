BuildTask UpdateVersion -Stage Publish -Order 0 -Definition {
    Update-Metadata $buildInfo.Path.Manifest.Name -PropertyName ModuleVersion -Value $buildInfo.Version
}