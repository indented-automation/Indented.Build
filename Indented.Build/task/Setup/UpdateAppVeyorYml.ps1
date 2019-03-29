BuildTask UpdateAppVeyorYml -Stage Setup -Order 2 -If {
    $appVeyorYml = Join-Path $buildInfo.Path.ProjectRoot 'appveyor.yml'

    $null -ne $env:SecureNugetApiKey -and
    (Test-Path $appVeyorYml) -and
    (Get-Item $appVeyorYml).Length -eq 0
} -Definition {
    # Adds appveyor.yml is an empty appveyor.yml file exists.

    $path = Join-Path $buildInfo.ProjectRoot 'appveyor.yml'
    $content = @(
        'os: WMF 5'
        ''
        'version: 1.0.{build}'
        ''
        'environment:'
        '  NuGetApiKey:'
        '    secure: {0}'
        ''
        'skip_commits:'
        '  message: /updated? readme.*s/'
        ''
        'build: false'
        ''
        'install:'
        '  - ps: |'
        '      $null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force'
        '      Set-PSRepository -Name PSGallery -InstallationPolicy Trusted'
        '      Install-Module Configuration, Pester, Indented.Build'
        '      Set-Location $env:APPVEYOR_BUILD_FOLDER\$env:APPVEYOR_PROJECT_NAME'
        '      Get-BuildInfo -BuildType Build'
        ''
        'build_script:'
        '  - ps: Start-Build -BuildType Build'
        ''
        'test_script:'
        '  - ps: Start-Build -BuildType Test'
    ) -f $env:SecureNugetApiKey
    Set-Content $path -Value $content
}