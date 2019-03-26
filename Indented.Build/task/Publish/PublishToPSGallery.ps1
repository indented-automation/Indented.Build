BuildTask PublishToPSGallery -Stage Publish -Order 100 -If {
    $env:NuGetApiKey
} -Definition {
    Publish-Module -Path $buildInfo.Path.Build.Module -NuGetApiKey $env:NuGetApiKey -Repository PSGallery -ErrorAction Stop
}