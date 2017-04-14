BuildTask PublishToPSGallery -Stage Publish -Properties @{
    Order          = 1
    ValidWhen      = { $null -ne $env:NuGetApiKey }
    Implementation = {
        $erroractionpreference = 'Stop'
        try {
            Publish-Module -Path $buildInfo.ReleaseManifest -NuGetApiKey $env:NuGetApiKey -Repository PSGallery
        } catch {
            throw
        }
    }
}