BuildTask BuildSolution -Stage Build -Properties @{
    Order          = 3
    ValidWhen      = { Test-Path (Join-Path $this.Source 'class\*.sln') }
    Implementation = {
        Push-Location 'class'
        
        try {
            $null = Get-Command msbuild
            
            nuget restore

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
            Pop-Location
        }
    }
}