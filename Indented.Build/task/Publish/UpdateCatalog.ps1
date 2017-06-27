BuildTask UpdateCatalog -Stage Publish -Order 2 -If { $null -ne $env:CodeSigningCertificate } -Definition {
    New-FileCatalog $buildInfo.Path.Package -Path $buildInfo.Path.Package -CatalogVersion $buildInfo.Version
}