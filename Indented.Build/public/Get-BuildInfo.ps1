function Get-BuildInfo {
    [CmdletBinding()]
    [OutputType('BuildInfo')]
    param (
        [BuildType]$BuildType = 'Setup, Build, Test',

        [ReleaseType]$ReleaseType = 'Build'
    )

    New-Object BuildInfo($BuildType, $ReleaseType)
}