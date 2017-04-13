# Stub loader

foreach ($folder in 'enumeration', 'class', 'public') {
    Get-ChildItem (Join-Path $psscriptroot $folder) -Recurse -File -Filter *.ps1 | ForEach-Object {
        . $_.FullName
    }
}