BuildTask CopyModuleFiles -Stage Build -Order 3 -Definition {
    Get-BuildItem -Type Static | Copy-Item -Destination $buildInfo.Path.Package -Recurse -Force
}