BuildTask BuildSolution -Stage Build -Order 3 -If { Test-Path (Join-Path $buildInfo.Path.Source 'class*\*.sln') } -Definition {
        try {
        Push-Location (Resolve-Path 'class*').Path

        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile('https://dist.nuget.org/win-x86-commandline/latest/nuget.exe', "$pwd\nuget.exe")

        .\nuget.exe restore

        msbuild /t:Clean /t:Build /p:DebugSymbols=false /p:DebugType=None
        if ($lastexitcode -ne 0) {
            throw 'msbuild failed'
        }

        $path = (Join-Path $buildInfo.Package 'lib')
        if (-not (Test-Path $path)) {
            $null = New-Item $path -ItemType Directory -Force
        }

        Get-Item * -Exclude *.tests, packages | Where-Object PsIsContainer | ForEach-Object {
            Get-ChildItem $_.FullName -Filter *.dll -Recurse |
                Where-Object FullName -like '*bin*' |
                Copy-Item -Destination $path
        }
    } catch {
        throw
    } finally {
        if (Test-Path .\nuget.exe) {
            Remove-Item .\nuget.exe
        }
        Pop-Location
    }
}