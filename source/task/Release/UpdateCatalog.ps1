BuildTask UpdateCatalog -Stage Release -Properties @{
    Order          = 1
    ValidWhen      = { $null -ne $env:CODESIGNINGCERTIFICATE }
    Implementation = {
        New-FileCatalog $buildInfo.Package -Path $buildInfo.Package -CatalogVersion $buildInfo.Version
    }
}