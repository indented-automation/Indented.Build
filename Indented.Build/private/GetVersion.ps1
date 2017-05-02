function GetVersion {
    [OutputType([Version])]
    param (
        [System.IO.FileInfo]$SourceManifest
    )

    Get-Metadata -Path $SourceManifest.FullName -PropertyName ModuleVersion
}