BuildTask UpdateAppVeyorYml -Stage Setup -Properties @{
    Order          = 0
    ValidWhen      = { -not (Test-Path (Join-Path $buildInfo.ProjectRoot 'appveyor.yml')) }
    Implementation = {
        $path = Join-Path $buildInfo.ProjectRoot 'appveyor.yml'
        $content = 'os: WMF 5',
                   '',
                   'version: 1.0.{build}.0',
                   '',
                   'skip_commits:',
                   '  message: /updated? readme.*s/',
                   '',
                   'build: false',
                   '',
                   'install:',
                   '  - ps: |',
                   '    $null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force',
                   '    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted',
                   '    Install-Module Configuration, Pester, Indented.Build',
                   '    Set-Location $env:APPVEYOR_BUILD_FOLDER\$env:APPVEYOR_PROJECT_NAME',
                   '    Get-BuildInfo -BuildType Build',
                   '',
                   'build_script:',
                   '  - ps: Start-Build -BuildType Build',
                   '',
                   'test_script:',
                   '  - ps: Start-Build -BuildType Test'
        Set-Content $path -Value $content
    }
}