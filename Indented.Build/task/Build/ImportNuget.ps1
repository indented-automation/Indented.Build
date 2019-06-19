BuildTask ImportNuget -Stage Build -If {
    Test-Path (Join-Path $buildInfo.Path.Source.Module 'packages.config')
} -Definition {
    # Downloads and embeds dlls from nuget packages using a packages.config file.

    $destinationPath = Join-Path $buildInfo.Path.Build.Module 'lib'
    if (-not (Test-Path $destinationPath)) {
        $null = New-Item $destinationPath -ItemType Directory
    }

    $configPath = Join-Path $buildInfo.Path.Source.Module 'packages.config'
    foreach ($package in ([Xml](Get-Content $configPath -Raw)).packages.package) {
        $packageMetadata = Find-Package -Name $package.id -RequiredVersion $package.Version -Source NuGet

        $uri = 'https://www.nuget.org/api/v2/package/{0}/{1}' -f @(
            $packageMetadata.Name
            $packageMetadata.Version
        )

        $nupkgPath = '{0}.zip' -f (Join-Path $buildInfo.Path.Build.Output $packageMetadata.PackageFileName)
        [System.Net.WebClient]::new().DownloadFile(
            $uri,
            $nupkgPath
        )

        $archivePath = Join-Path $buildInfo.Path.Build.Output $packageMetadata.Name
        Expand-Archive $nupkgPath -DestinationPath $archivePath
        $assembly = Get-ChildItem $archivePath -Filter *.dll -Recurse |
            Where-Object FullName -notmatch '\\(portable|netstandard)' |
            ForEach-Object {
                # Ignore netstandard and portable
                $FrameworkVersion = if ($_.FullName -match '\\(?<Version>net\d+)') {
                    $matches['Version']
                } else {
                    0
                }

                [PSCustomObject]@{
                    Path             = $_.FullName
                    FrameworkVersion = $FrameworkVersion
                    NumericVersion   = [Int]($FrameworkVersion -replace 'net')
                }
            } |
            Sort-Object NumericVersion -Descending |
            Where-Object { -not $package.FrameworkVersion -or $_.NumericVersion -le [Int]($package.FrameworkVersion -replace 'net') } |
            Select-Object -First 1

        Copy-Item -Path $assembly.Path -Destination $destinationPath

        Remove-Item $archivePath -Recurse
        Remove-Item $nupkgPath
    }
}