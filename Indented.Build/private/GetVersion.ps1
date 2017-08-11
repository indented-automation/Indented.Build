function GetVersion {
    [OutputType([Version])]
    param (
        # The path to the a module manifest file.
        [String]$Path
    )

    if ($Path -and (Test-Path $Path)) {
        $manifestContent = Import-PowerShellDataFile $Path
        $versionString = $manifestContent.ModuleVersion

        $version = [Version]'0.0.0'
        if ([Version]::TryParse($versionString, [Ref]$version)) {
            if ($version.Build -eq -1) {
                return [Version]::new($version.Major, $version.Minor, 0)
            } else {
                return $version
            }
        }
    }

    return [Version]'1.0.0'
}