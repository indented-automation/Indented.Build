BuildTask UpdateCatalog -Stage Publish -Order 2 -If {
    $env:CodeSigningCertificate
} -Definition {
    New-FileCatalog $buildInfo.Path.Build.Module -Path $buildInfo.Path.Build.Module -CatalogVersion $buildInfo.Version
}