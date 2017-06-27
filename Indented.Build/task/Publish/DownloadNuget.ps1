task DownloadNuget -if (-not (Get-Command nuget -ErrorAction SilentlyContinue)) {
    $nuget = Join-Path $buildInfo.Path.Output 'nuget.exe'

    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile(
        'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe',
        $nuget
    )
    Set-Alias nuget $nuget
}