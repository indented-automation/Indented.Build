BuildTask PublishToCurrentUser -Stage Publish -Properties @{
    ValidWhen      = { $null -ne $env:NuGetApiKey }
    Implementation = {
        Import-Module $buildInfo.ReleaseManifest
        Publish-Module $buildInfo.ModuleName -NuGetApiKey $env:NuGetApiKey -Repository PSGallery
    }
}