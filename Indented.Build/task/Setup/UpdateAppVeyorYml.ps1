BuildTask UpdateAppVeyorYml -Stage Setup -Order 2 -If {
    $appVeyorYml = Join-Path $buildInfo.Path.ProjectRoot 'appveyor.yml'

    (Test-Path $appVeyorYml) -and
    (Get-Item $appVeyorYml).Length -eq 0
} -Definition {
    # Adds appveyor.yml if an empty appveyor.yml file exists.

    $path = Join-Path $buildInfo.ProjectRoot 'appveyor.yml'
    $content = @(
        'image: Visual Studio 2017'
        ''
        'version: 1.0.0.{build}'
        ''
        'branches:'
        '  only: master'
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
        '  - pwsh: Set-Location $env:APPVEYOR_BUILD_FOLDER\$env:APPVEYOR_PROJECT_NAME'
        ''
        'build_script:'
        '  - ps: Start-Build -BuildType Setup, Build'
        ''
        'test_script:'
        '  - ps: Start-Build -BuildType Setup, Test'
        '  - pwsh: Start-Build -BuildType Setup, Test'
    ) -f $env:SecureNugetApiKey

    Set-Content $path -Value $content
}