BuildTask PublishToPSGallery -Stage Publish -Properties @{
    Order          = 1
    ValidWhen      = { $null -ne $env:NuGetApiKey }
    Implementation = {
        Publish-Module -Path $buildInfo.Package -NuGetApiKey $env:NuGetApiKey -Repository PSGallery -ErrorAction Stop
    }
}