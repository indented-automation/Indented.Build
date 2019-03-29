BuildTask UpdateCatalog -Stage Publish -Order 2 -If {
    $env:CodeSigningCertificate
} -Definition {
    # If a code signing certificate is defined, generate a catalog.

    New-FileCatalog $buildInfo.Path.Build.Module -Path $buildInfo.Path.Build.Module -CatalogVersion $buildInfo.Version
}