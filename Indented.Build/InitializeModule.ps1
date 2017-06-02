function InitializeModule {
    # Fill the build task cache. This makes the module immune to source file deletion once the cache is filled (when building itself).
    $null = Get-BuildTask -ListAvailable
}