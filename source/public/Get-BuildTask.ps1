function Get-BuildTask {
    [CmdletBinding()]
    param( )

    Get-ChildItem (Join-Path $psscriptroot 'task') -File -Recurse | ForEach-Object {
        . $_.FullName
    }
}