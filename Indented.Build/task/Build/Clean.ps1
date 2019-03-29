BuildTask Clean -Stage Build -Order 0 -Definition {
    # Clean old content from the build directories.

    $erroractionprefence = 'Stop'

    try {
        if (Get-Module $buildInfo.ModuleName) {
            Remove-Module $buildInfo.ModuleName
        }

        if (Test-Path $buildInfo.Path.Build.Module.Parent.FullName) {
            Remove-Item $buildInfo.Path.Build.Module.Parent.FullName -Recurse -Force
        }

        $nupkg = Join-Path $buildInfo.Path.Build.Package ('{0}.*.nupkg' -f $buildInfo.ModuleName)
        if (Test-Path $nupkg) {
            Remove-Item $nupkg
        }

        if (Test-Path $buildInfo.Path.Build.Output) {
            Remove-Item $buildInfo.Path.Build.Output -Recurse -Force
        }

        $null = New-Item $buildInfo.Path.Build.Module -ItemType Directory -Force
        $null = New-Item $buildInfo.Path.Build.Package -ItemType Directory -Force

        if (-not (Test-Path $buildInfo.Path.Build.Output)) {
            $null = New-Item $buildInfo.Path.Build.Output -ItemType Directory -Force
        }
    } catch {
        throw
    }
}