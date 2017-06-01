function GetSourcePath {
    [OutputType([System.IO.DirectoryInfo])]
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$ProjectRoot
    )

    if ((Test-Path '*.psd1') -and ((Get-Item '*.psd1').BaseName -eq (Get-Item $pwd).Name)) {
        [System.IO.DirectoryInfo]$pwd.Path
    } elseif (Test-Path (Join-Path $ProjectRoot $ProjectRoot.Name)) {
        [System.IO.DirectoryInfo](Join-Path $ProjectRoot $ProjectRoot.Name)
    } else {
        throw 'Unable to determine the source path'
    }
}