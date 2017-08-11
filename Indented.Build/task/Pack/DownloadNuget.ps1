BuildTask DownloadNuget -Stage Pack -If { -not (Get-Command nuget -ErrorAction SilentlyContinue) } -Order 1 -Definition {
    $nuget = Join-Path $buildInfo.Path.Output 'nuget.exe'

    if (-not (Test-Path $nuget)) {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile(
            'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe',
            $nuget
        )
    }
    Set-Alias nuget $nuget -Scope Script
}