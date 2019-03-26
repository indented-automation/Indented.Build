BuildTask UploadAppVeyorTestResults -Stage Test -Order 3 -If {
    $buildInfo.BuildSystem -eq 'AppVeyor'
} -Definition {
    $path = Join-Path $buildInfo.Path.Build.Output ('{0}.xml' -f $buildInfo.ModuleName)
    if (Test-Path $path) {
        [System.Net.WebClient]::new().UploadFile(('https://ci.appveyor.com/api/testresults/nunit/{0}' -f $env:APPVEYOR_JOB_ID), $path)
    }
}