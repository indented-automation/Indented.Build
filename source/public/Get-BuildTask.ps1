function Get-BuildTask {
    [CmdletBinding()]
    [OutputType('BuildTask')]
    param (
        $Name = '*'
    )

    if (-not $Name.EndsWith('.ps1') -and -not $Name.EndsWith('*')) {
        $Name += '.ps1'
    }

    if ((Split-Path $psscriptroot -Leaf) -eq 'public') {
        $path = Join-Path $psscriptroot '..\task'
    } else {
        $path = Join-Path $psscriptroot 'task'
    }
    Get-ChildItem $path -File -Filter $Name -Recurse | ForEach-Object {
        . $_.FullName
    }
}