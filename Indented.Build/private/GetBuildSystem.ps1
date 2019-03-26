function GetBuildSystem {
    [OutputType([String])]
    param ( )

    if ($env:APPVEYOR -eq $true) { return 'AppVeyor' }
    if ($env:JENKINS_URL)        { return 'Jenkins' }

    return 'Desktop'
}