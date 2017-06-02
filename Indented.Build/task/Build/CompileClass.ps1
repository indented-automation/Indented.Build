BuildTask CompileClass -Stage Build -If { -not (Test-Path (Join-Path $buildInfo.Path.Source 'class*\*.sln')) -and -not (Test-Path (Join-Path $buildInfo.Path.Source 'class*\*.*proj')) -and (Test-Path (Join-Path $buildInfo.Path.Source 'class*\*.cs')) } -Definition {
    $outputPath = Join-Path $buildInfo.Path.Package.FullName 'lib'

    $typeDefinition = Get-ChildItem 'class*\*.cs' -ErrorAction SilentlyContinue | Get-Content | Out-String
    $params = @{
        TypeDefinition = $typeDefinition
        OutputType     = 'Library'
        OutputPath     = $outputPath
    }
    Add-Type @params
}