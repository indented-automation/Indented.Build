function Clean {
    # Clean the build directory

    try {
        if (Test-Path build\package) {
            Remove-Item build\package -Recurse -Force
        }
        $null = New-Item build\package -ItemType Directory -Force
    } catch {
        $buildInfo.State = 'Failed'
        $buildInfo.Exception = $_.Exception.Message
    }
}