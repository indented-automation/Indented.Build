BuildTask TestModuleImport -Stage Test -Order 0 -Definition {
    $script = {
        param (
            $buildInfo
        )

        $path = Join-Path $buildInfo.Path.Source.Module 'test*'

        if (Test-Path (Join-Path $path 'stub')) {
            Get-ChildItem (Join-Path $path 'stub') -Filter *.psm1 -Recurse -Depth 1 | ForEach-Object {
                Import-Module $_.FullName -Global -WarningAction SilentlyContinue
            }
        }

        Import-Module $buildInfo.Path.Build.Manifest.FullName -ErrorAction Stop
    }

    if ($buildInfo.BuildSystem -eq 'Desktop') {
        Start-Job -ArgumentList $buildInfo -ScriptBlock $script | Receive-Job -Wait -ErrorAction Stop
    } else {
        & $script -BuildInfo $buildInfo
    }
}