BuildTask PublishToPSGallery -Stage Publish -Properties @{
    Order          = 1
    ValidWhen      = { $null -ne $env:NuGetApiKey }
    Implementation = {
        $erroractionpreference = 'Stop'
        try {
            Import-Module $buildInfo.ModuleName
            Publish-Module $buildInfo.ModuleName -NuGetApiKey $env:NuGetApiKey -Repository PSGallery
        } catch {
            throw
        }
    }
}