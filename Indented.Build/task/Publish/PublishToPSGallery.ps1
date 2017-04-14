BuildTask PublishToCurrentUser -Stage Publish -Properties @{
    Order          = 1
    ValidWhen      = { $null -ne $env:NuGetApiKey }
    Implementation = {
        Import-Module $buildInfo.ModuleName
        Publish-Module $buildInfo.ModuleName -NuGetApiKey $env:NuGetApiKey -Repository PSGallery
    }
}