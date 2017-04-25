BuildTask UpdateAppVeyorVersion -Stage Setup -Properties @{
    Order          = 1
    ValidWhen      = { Test-Path (Join-Path $buildInfo.ProjectRoot 'appveyor.yml') }
    Implementation = {
        $versionString = '{0}.{1}.{{build}}' -f $buildInfo.Version.Major, $buildInfo.Version.Minor

        $path = Join-Path $buildInfo.ProjectRoot 'appveyor.yml'
        $content = Get-Content $path -Raw
        $content = $content -replace 'version: .+', ('version: {0}' -f $versionString)
        Set-Content $path -Value $content -NoNewLine
    }
}