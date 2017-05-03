function UpdateVersion {
    <#
    .SYNOPSIS
        Generate a new version number.
    .DESCRIPTION
        Generate a new version number according to the release type.
    #>

    [CmdletBinding()]
    [OutputType([Version])]
    param (
        # The release type.
        [ValidateSet('Build', 'Minor', 'Major')]
        [String]$ReleaseType = 'Build',

        # The current version number.
        [Parameter(ValueFromPipeline = $true)]
        [Version]$Version
    )

    process {
        $arguments = switch ($ReleaseType) {
            'Major' { ($Version.Major + 1), 0, 0 }
            'Minor' { $Version.Major, ($Version.Minor + 1), 0 }
            'Build' { $Version.Major, $Version.Minor, ($Version.Build + 1) }
        }
        return New-Object Version($arguments)
    }
}