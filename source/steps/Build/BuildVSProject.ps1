function BuildVSProject {
    [BuildStep('Build')]
    param( )

    $path = Join-Path 'source\classes'

    if (Test-Path "$path\*.*proj") {
        Push-Location $path
        
        Get-Item "$path\*.*proj" | ForEach-Object {
            $proj = [Xml](Get-Content $_.FullName)
            if ($proj.Project.PropertyGroup.OutputType -eq 'winexe') {
                $outputPath = Join-Path $buildInfo.ModuleBase.FullName 'bin'
            } else {
                $outputPath = Join-Path $buildInfo.ModuleBase.FullName 'lib'
            }
            if (-not (Test-Path $outputPath)) {
                $null = New-Item $outputPath -ItemType Directory -Force
            }

            msbuild /t:Clean /t:Build /p:OutputPath=$outputPath /p:DebugSymbols=false /p:DebugType=None $_.Name
        }

        Pop-Location
    }
}