BuildTask CopyModuleFiles -Stage Build -Order 3 -Definition {
    try {
        $buildInfo |
            Get-BuildItem -Type Static |
            Copy-Item -Destination $buildInfo.Path.Build.Module -Recurse -Force
    } catch {
        throw
    }
}