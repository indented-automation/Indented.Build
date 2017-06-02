function GetVersion {
    [OutputType([Version])]
    param (
        # The path to the a module manifest file.
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [String]$Path
    )

    if (Test-Path $Path) {
        $manifestContent = Import-PowerShellDataFile $Path
        $versionString = $manifestContent.ModuleVersion

        $version = [Version]'0.0.0'
        if ([Version]::TryParse($versionString, [Ref]$version)) {
            return $version
        }
    }

    return [Version]'1.0.0'
}