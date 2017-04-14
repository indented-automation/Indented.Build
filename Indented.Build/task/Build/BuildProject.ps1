BuildTask BuildProject -Stage Build -Properties @{
    Order          = 0
    ValidWhen      = { (Test-Path (Join-Path $this.Source 'class\*.*proj')) -and -not (Test-Path (Join-Path $this.Source 'class\*.sln')) }
    Implementation = {
        Push-Location 'class'
        
        try {
            $null = Get-Command msbuild
            
            Get-Item '*.*proj' | ForEach-Object {
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
        } catch {
            throw
        } finally {
            Pop-Location
        }
    }
}