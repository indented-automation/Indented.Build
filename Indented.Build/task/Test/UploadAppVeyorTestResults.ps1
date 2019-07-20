BuildTask UploadAppVeyorTestResults -Stage Test -Order 1024 -If {
    $buildInfo.BuildSystem -eq 'AppVeyor'
} -Definition {
    # Upload any test results to AppVeyor.

    $path = Join-Path $buildInfo.Path.Build.Output ('{0}-nunit.xml' -f $buildInfo.ModuleName)
    if (Test-Path $path) {
        [System.Net.WebClient]::new().UploadFile(('https://ci.appveyor.com/api/testresults/nunit/{0}' -f $env:APPVEYOR_JOB_ID), $path)
    }
}