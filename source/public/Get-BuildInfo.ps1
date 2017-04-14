function Get-BuildInfo {
    [CmdletBinding()]
    [OutputType('BuildInfo')]
    param (
        [BuildType]$BuildType = 'Build, Test',

        [ReleaseType]$ReleaseType = 'Build'
    )

    New-Object BuildInfo($BuildType, $ReleaseType)
}