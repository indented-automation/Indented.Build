BuildTask PublishToPSGallery -Stage Publish -Order 100 -If {
    $env:NuGetApiKey
} -Definition {
    # Publish the module to the PSGallery if a nuget key is in the NuGetApiKey environment variable.

    Publish-Module -Path $buildInfo.Path.Build.Module -NuGetApiKey $env:NuGetApiKey -Repository PSGallery -ErrorAction Stop
}