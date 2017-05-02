# Stub loader

foreach ($folder in 'enumeration', 'class', 'public', 'private') {
    Get-ChildItem (Join-Path $psscriptroot $folder) -Recurse -File -Filter *.ps1 | ForEach-Object {
        Write-Verbose $_.FullName

        . $_.FullName
    }
}