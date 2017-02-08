function ImportTest {
    # Attempt to import the module, abort the build if the module does not import.
    # If the manifest declares a minimum version use PowerShell -version <version> to execute a best-effort test against that version

    [BuildStep('BuildTest', Order = 0)]
    param( )

    $argumentList = @()
    $psVersion =  Get-Metadata (Join-Path $buildInfo.BuildPath $buildInfo.Manifest) -PropertyName PowerShellVersion -ErrorAction SilentlyContinue 
    if ($null -ne $psVersion -and ([Version]$psVersion).Major -lt $psversionTable.PSVersion.Major) {
        $argumentList += '-Version', $psVersion
    }
    $argumentList += '-NoProfile', '-Command', ('
        try {{
            Import-Module "{0}" -ErrorAction Stop
        }} catch {{
            $_.Exception.Message
            exit 1
        }}
        exit 0
    ' -f $buildInfo.Manifest)

    & powershell.exe $argumentList
}