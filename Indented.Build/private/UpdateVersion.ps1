function UpdateVersion {
    [OutputType([Version])]
    param (
        # The current version number.
        [Parameter(Position = 1, ValueFromPipeline = $true)]
        [Version]$Version,

        # The release type.
        [ValidateSet('Build', 'Minor', 'Major')]
        [String]$ReleaseType = 'Build'
    )

    process {
        $arguments = switch ($ReleaseType) {
            'Major' { ($Version.Major + 1), 0, 0 }
            'Minor' { $Version.Major, ($Version.Minor + 1), 0 }
            'Build' { $Version.Major, $Version.Minor, ($Version.Build + 1) }
        }
        New-Object Version($arguments)
    }
}