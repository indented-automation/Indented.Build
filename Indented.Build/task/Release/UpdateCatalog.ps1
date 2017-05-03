BuildTask UpdateCatalog -Stage Release -Order 1 -If { $null -ne $env:CodeSigningCertificate } -Definition {
    New-FileCatalog $buildInfo.Path.Package -Path $buildInfo.Path.Package -CatalogVersion $buildInfo.Version
}