BuildTask Clean -Stage Build -Properties @{
    ValidWhen      = { -not (Test-Path 'class\*.sln') -and (Test-Path 'class\*.cs') }
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