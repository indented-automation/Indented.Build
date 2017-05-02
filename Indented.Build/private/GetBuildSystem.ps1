function GetBuildSystem {
    <#
    .SYNOPSIS
        Get the build system name.
    .DESCRIPTION
        Attempt to determine the build system (if any) executing this script by inspecting the system.
    #>

    [OutputType([String])]
    param ( )

    if ($env:APPVEYOR -eq $true) { return 'AppVeyor' }
    if ($env:JENKINS_URL)        { return 'Jenkins' }

    return 'Unknown'
}