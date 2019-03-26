BuildTask PublishToCurrentUser -Stage Publish -Order 99 -Definition {
    $path = '{0}\Documents\WindowsPowerShell\Modules\{1}' -f $home, $buildInfo.ModuleName
    if (-not (Test-Path $path)) {
        $null = New-Item $path -ItemType Directory
    }
    Copy-Item $buildInfo.Path.Build.Module -Destination $path -Recurse -Force
}