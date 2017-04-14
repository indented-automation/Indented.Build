BuildTask UpdateCatalog -Stage Release -Properties @{
    Order          = 1
    ValidWhen      = { $null -ne $env:CodeSigningCertificate }
    Implementation = {
        New-FileCatalog $buildInfo.Package -Path $buildInfo.Package -CatalogVersion $buildInfo.Version
    }
}