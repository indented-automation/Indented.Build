BuildTask UploadAppVeyorTestResults -Stage Test -Properties @{
    Order          = 3
    ValidWhen      = { $null -ne $env:APPVEYOR_JOB_ID }
    Implementation = {
        $path = Join-Path $buildInfo.Output ('{0}.xml' -f $buildInfo.ModuleName)
        if (Test-Path $path) {
            $webClient = New-Object System.Net.WebClient
            $webClient.UploadFile(('https://ci.appveyor.com/api/testresults/nunit/{0}' -f $env:APPVEYOR_JOB_ID), $path)
        }
    }
}