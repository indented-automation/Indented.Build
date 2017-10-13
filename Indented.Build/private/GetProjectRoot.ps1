function GetProjectRoot {
    [OutputType([System.IO.DirectoryInfo])]
    param ( )

    [System.IO.DirectoryInfo](Get-Item (git rev-parse --show-toplevel)).FullName
}