BuildTask UpdateAppVeyorVersion -Stage Setup -Order 1 -If { Test-Path (Join-Path $buildInfo.Path.ProjectRoot 'appveyor.yml') } -Definition {
    $versionString = '{0}.{1}.{{build}}' -f $buildInfo.Version.Major, $buildInfo.Version.Minor

    $path = Join-Path $buildInfo.Path.ProjectRoot 'appveyor.yml'
    $content = Get-Content $path -Raw
    $content = $content -replace 'version: .+', ('version: {0}' -f $versionString)
    Set-Content $path -Value $content -NoNewLine
}