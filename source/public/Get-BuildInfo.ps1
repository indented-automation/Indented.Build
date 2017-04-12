function Get-BuildInfo {
    [CmdletBinding()]
    param(
        [BuildType]$BuildType = 'Build, Test',

        [String]$ReleaseType = 'Build'
    )

    $buildInfo = New-Object BuildInfo($BuildType, $ReleaseType)
}