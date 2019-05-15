BuildTask GetNuget -Stage Setup -If {
    -not (Get-Command nuget -ErrorAction SilentlyContinue)
} -Definition {
    # Nuget is reqruied by a number of build tasks. If nuget is not easily available, download a copy from nuget.org.

    $nuget = Join-Path $buildInfo.Path.Build.Output nuget.exe
    $webClient = [System.Net.WebClient]::new()
    $webClient.DownloadFile(
        'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe',
        $nuget
    )

    & $nuget restore

    Set-Alias nuget -Value $nuget -Scope 1
}