BuildTask Clean -Stage Build -If { -not (Test-Path 'class*\*.sln') -and -not (Test-Path 'class*\*.*proj') -and (Test-Path 'class*\*.cs') } -Definition {
    $outputPath = Join-Path $buildInfo.Path.Package.FullName 'lib'

    $typeDefinition = Get-ChildItem 'class*\*.cs' -ErrorAction SilentlyContinue | Get-Content | Out-String
    $params = @{
        TypeDefinition = $typeDefinition
        OutputType     = 'Library'
        OutputPath     = $outputPath
    }
}