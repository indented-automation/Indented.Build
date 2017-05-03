BuildTask PublishToCurrentUser -Stage Publish -Order 1 -Definition {
    $path = '{0}\Documents\WindowsPowerShell\Modules\{1}' -f $home, $buildInfo.ModuleName
    if (-not (Test-Path $path)) {
        $null = New-Item $path -ItemType Directory
    }
    Copy-Item $buildInfo.Path.Package -Destination $path -Recurse -Force
}