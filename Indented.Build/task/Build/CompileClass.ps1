BuildTask Clean -Stage Build -Properties @{
    ValidWhen      = { -not (Test-Path (Join-Path $buildInfo.Source 'class\*.sln')) -and -not (Test-Path (Join-Path $this.Source 'class\*.*proj')) -and (Test-Path (Join-Path $buildInfo.Source 'class\*.cs')) }
    Implementation = {
        $outputPath = Join-Path $buildInfo.ModuleBase.FullName 'lib'

        $typeDefinition = Get-ChildItem 'class\*.cs' -ErrorAction SilentlyContinue | Get-Content | Out-String
        $params = @{
            TypeDefinition = $typeDefinition
            OutputType     = 'Library'
            OutputPath     = $outputPath
        }
    }
}