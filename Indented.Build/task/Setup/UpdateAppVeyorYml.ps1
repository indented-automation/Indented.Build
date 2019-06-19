﻿BuildTask UpdateAppVeyorYml -Stage Setup -Order 2 -If {
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
        '      Install-Module InvokeBuild, Indented.Build'
        '      Set-Location $env:APPVEYOR_BUILD_FOLDER'
        '  - pwsh: |'
        '      Install-Module InvokeBuild, Indented.Build'
        '      Set-Location $env:APPVEYOR_BUILD_FOLDER'
        ''
        'build_script:'
        '  - ps: Start-Build -BuildType Setup, Build'
        ''
        'test_script:'
        '  - ps: Start-Build -BuildType Setup, Test'
        '  - pwsh: Start-Build -BuildType Setup, Test'
        ''
        'on_success:'
        '  - ps: |'
        '      $buildInfo = Get-BuildInfo'
        '      [Version]$tagVersion = (git describe --tags --abbrev=0 2>$null) -replace "^v"'
        ''
        '      if ($tagVersion -eq $buildInfo.Version) {'
        '          $galleryVersion = [Version](Find-Module $buildInfo.ModuleName).Version'
        '          if ($buildInfo.Version -gt $galleryVersion) {'
        '              Start-Build -BuildType Setup, Publish'
        '          } else {'
        '              Write-Host "Skipping publish: Already published" -ForegroundColor Greed'
        '          }'
        '      } else {'
        '          Write-Host "Skipping publish: Last tag does not match build version" -ForegroundColor Yellow'
        '      }'
    )

    Set-Content $path -Value $content
}