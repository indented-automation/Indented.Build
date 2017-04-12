BuildTask BuildProject -Stage Build -Properties @{
    Order          = 0
    ValidWhen      = { Test-Path "class\*.*proj" }
    Implementation = {
        Push-Location $path
        
        Get-Item 'class\*.*proj' | ForEach-Object {
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