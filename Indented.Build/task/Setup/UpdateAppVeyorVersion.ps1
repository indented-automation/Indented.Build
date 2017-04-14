BuildTask UpdateAppVeyorVersion -Stage Setup -Properties @{
    ValidWhen      = { Test-Path (Join-Path $this.ProjectRoot 'appveyor.yml') }
    Implementation = {
        $versionString = '{0}.{1}.{{build}}.0' -f $buildInfo.Version.Major, $buildInfo.Version.Minor

        $path = Join-Path $buildInfo.ProjectRoot 'appveyor.yml'
        $content = Get-Content $path -Raw
        $content = $content -replace 'version: .+', ('version: {0}' -f $versionString)
        Set-Content $path -Value $content -NoNewLine
    }
}