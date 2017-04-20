function Test-CIServer {
    <#
    .SYNOPSIS
        Attempts to determine if the host executing a build is a CI server.
    .DESCRIPTION
        Attempts to determine if the host executing a build is a CI server.

        State is typically evaluated by inspecting environment variables specific to each CI server type.
    .NOTES
        Change log:
            20/04/2017 - Chris Dent - Created.
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ( )

    if ($env:APPVEYOR -eq $true) {
        return $true
    }
    if ($env:JENKINS_URL) {
        return $true
    }

    return $false
}