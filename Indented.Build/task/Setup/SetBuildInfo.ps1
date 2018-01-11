BuildTask SetBuildInfo -Stage Setup -Order 0 -If { -not $Script:BuildInfo } -Definition {
    $Script:BuildInfo = Get-BuildInfo
}