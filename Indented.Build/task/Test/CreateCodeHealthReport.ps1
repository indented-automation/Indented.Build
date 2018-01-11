BuildTask CreateCodeHealthReport -Stage Test -If { Get-Module PSCodeHealth -ListAvailable } -Definition {
    Start-Job -ArgumentList $buildInfo -ScriptBlock {
        param (
            $buildInfo
        )

        $path = Join-Path $buildInfo.Path.Source 'test*'

        if (Test-Path (Join-Path $path 'stub')) {
            Get-ChildItem (Join-Path $path 'stub') -Filter *.psm1 -Recurse -Depth 1 | ForEach-Object {
                Import-Module $_.FullName -Global -WarningAction SilentlyContinue
            }
        }

        Import-Module $buildInfo.Path.Manifest -Global -ErrorAction Stop
        $params = @{
            Path           = $buildInfo.Path.RootModule
            Recurse        = $true
            TestsPath      = $path
            HtmlReportPath = Join-Path $buildInfo.Path.Output ('{0}-code-health.html' -f $buildInfo.ModuleName)
        }
        Invoke-PSCodeHealth @params
    } | Receive-Job -Wait
}