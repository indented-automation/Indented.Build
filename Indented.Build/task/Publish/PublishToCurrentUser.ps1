BuildTask PublishToCurrentUser -Stage Publish -Properties @{
    Order          = 0
    Implementation = {
        $path = '{0}\Documents\WindowsPowerShell\Modules\{1}' -f $home, $buildInfo.ModuleName
        if (-not (Test-Path $path)) {
            $null = New-Item $path -ItemType Directory
        }
        Copy-Item $buildInfo.Package -Destination $path -Recurse
    }
}