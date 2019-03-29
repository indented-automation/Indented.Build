BuildTask SetBuildInfo -Stage Setup -Order 0 -If {
    -not $Script:BuildInfo
} -Definition {
    # BuildInfo is discovered. If more than one module is available to be built an error will be raised.

    $params = @{}
    if ($Script:moduleName) {
        $params.Add('ModuleName', $Script:moduleName)
    }
    $Script:BuildInfo = Get-BuildInfo @params

    if (@($Script:BuildInfo).Count -gt 1) {
        throw 'Either a unique module name must be supplied or the BuildAll task must be used to build all modules.'
    }
}