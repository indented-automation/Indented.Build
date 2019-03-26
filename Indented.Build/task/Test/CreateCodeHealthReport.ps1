BuildTask CreateCodeHealthReport -Stage Test -If {
    Get-Module PSCodeHealth -ListAvailable
} -Definition {
     $script = {
        param (
            $buildInfo
        )

        $path = Join-Path $buildInfo.Path.Source.Module 'test*'

        if (Test-Path (Join-Path $path 'stub')) {
            Get-ChildItem (Join-Path $path 'stub') -Filter *.psm1 -Recurse -Depth 1 | ForEach-Object {
                Import-Module $_.FullName -Global -WarningAction SilentlyContinue
            }
        }

        Import-Module $buildInfo.Path.Build.Manifest -Global -ErrorAction Stop
        $params = @{
            Path           = $buildInfo.Path.Build.RootModule
            Recurse        = $true
            TestsPath      = $path
            HtmlReportPath = Join-Path $buildInfo.Path.Build.Output 'code-health.html'
        }
        Invoke-PSCodeHealth @params
    }

    if ($buildInfo.BuildSystem -eq 'Desktop') {
        Start-Job -ArgumentList $buildInfo -ScriptBlock $script | Receive-Job -Wait
    } else {
        & $script -BuildInfo $buildInfo
    }
}