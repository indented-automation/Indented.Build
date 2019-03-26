BuildTask CreateChocoPackage -Stage Pack -If {
    Get-Command choco -ErrorAction SilentlyContinue
} -Definition {
    $script = {
        param (
            $buildInfo
        )

        Import-Module $buildInfo.Path.Build.Manifest

        Get-Module $buildInfo.ModuleName | ConvertTo-ChocoPackage -Path $buildInfo.Path.Build.Package
    }


    if ($buildInfo.BuildSystem -eq 'Desktop') {
        Start-Job -ArgumentList $buildInfo -ScriptBlock $script | Receive-Job -Wait
    } else {
        & $script -BuildInfo $buildInfo
    }
}