BuildTask BuildSolution -Stage Build -Order 3 -If {
    Test-Path (Join-Path $buildInfo.Path.Source.Module 'class*\*.sln')
} -Definition {
    # Use msbuild to build a If a Visual Studio solution.
    #
    # Executes if a solution file is present in the class directory.

    try {
        Push-Location (Resolve-Path 'class*').Path

        nuget restore

        msbuild /t:Clean /t:Build /p:DebugSymbols=false /p:DebugType=None
        if ($lastexitcode -ne 0) {
            throw 'msbuild failed'
        }

        $path = (Join-Path $buildInfo.Path.Build.Module 'lib')
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
        Pop-Location
    }
}