function GetVersion {
    <#
    .SYNOPSIS
        Get the current module version.
    .DESCRIPTION
        Get the current module version.
    #>

    [OutputType([Version])]
    param (
        # The path to the a module manifest file.
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [String]$Path
    )

    # Fall back on version numbers in the manifest.
    if (Test-Path $Path) {
        $versionString = Get-Metadata -Path $Path -PropertyName ModuleVersion

        $version = [Version]'0.0.0'
        if ([Version]::TryParse($versionString, [Ref]$version)) {
            return $version
        }
    }

    return [Version]'1.0.0'
}