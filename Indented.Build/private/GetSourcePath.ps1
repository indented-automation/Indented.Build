function GetSourcePath {
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$ProjectRoot
    )

    try {
        Push-Location $ProjectRoot

        # Try and find a unique match by searching for ps1 files
        $sourcePath = Get-ChildItem .\*\*.psd1 |
            Where-Object { $_.BaseName -eq $_.Directory.Name } |
            ForEach-Object { $_.Directory.FullName }

        if (@($sourcePath).Count -eq 1) {
            return $sourcePath
        } else {
            if (Test-Path (Join-Path $ProjectRoot $ProjectRoot.Name)) {
                return [System.IO.DirectoryInfo](Join-Path $ProjectRoot $ProjectRoot.Name)
            }
        }

        throw 'Unable to determine the source path'
    } catch {
        $pscmdlet.ThrowTerminatingError($_)
    } finally {
        Pop-Location
    }
}