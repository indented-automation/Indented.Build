function Export-BuildScript {
    <#
    .SYNOPSIS
        Export a persistent build script.
    .DESCRIPTION
        Export a persistent build script (as .build.ps1).
    .INPUTS
        BuildInfo (from Get-BuildInfo)
    #>

    [CmdletBinding()]
    [OutputType([Void])]
    param (
        # The build information object is used to determine which tasks are applicable.
        [Parameter(ValueFromPipeline = $true)]
        [PSTypeName('BuildInfo')]
        [PSObject]$BuildInfo = (Get-BuildInfo),

        # By default the build system is automatically discovered. The BuildSystem parameter overrides any automatically discovered value. Tasks associated with the build system are added to the generated script.
        [String]$BuildSystem
    )

    if ($BuildSystem) {
        $BuildInfo.BuildSystem = $BuildSystem
    }

    $BuildInfo | Get-BuildTask
}