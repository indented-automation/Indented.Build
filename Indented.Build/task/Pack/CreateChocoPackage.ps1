BuildTask CreateChocoPackage -Stage Pack -If {
    $buildInfo.Config.CreateChocoPackage -eq $true -and
    (Get-Command choco -ErrorAction SilentlyContinue)
} -Definition {
    # Create a choco package for the module.

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