BuildTask CopyModuleFiles -Stage Build -Order 3 -Definition {
    # Copy files which should not be merged into the psm1 into the build area.

    try {
        $buildInfo |
            Get-BuildItem -Type Static |
            Copy-Item -Destination $buildInfo.Path.Build.Module -Recurse -Force
    } catch {
        throw
    }
}