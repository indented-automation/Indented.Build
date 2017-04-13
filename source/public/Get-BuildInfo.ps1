function Get-BuildInfo {
    [CmdletBinding()]
    param(
        [BuildType]$BuildType = 'Build, Test',

        [String]$ReleaseType = 'Build'
    )

    New-Object BuildInfo($BuildType, $ReleaseType)
}