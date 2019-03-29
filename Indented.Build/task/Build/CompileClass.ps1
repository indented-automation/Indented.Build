BuildTask CompileClass -Stage Build -If {
    -not (Test-Path (Join-Path $buildInfo.Path.Source.Module 'class*\*.sln')) -and
    -not (Test-Path (Join-Path $buildInfo.Path.Source.Module 'class*\*.*proj')) -and
    (Test-Path (Join-Path $buildInfo.Path.Source.Module 'class*\*.cs'))
} -Definition {
    # If the class directory contains cs files, and does not contain proj or solution files, use Add-Type to generate a compiled assembly.

    $outputPath = Join-Path $buildInfo.Path.Build.Module.FullName 'lib'
    if (-not (Test-Path $outputPath)) {
        $null = New-Item $outputPath -ItemType Directory -Force
    }

    $typeDefinition = Get-ChildItem 'class*\*.cs' -ErrorAction SilentlyContinue |
        Get-Content |
        Out-String
    $params = @{
        TypeDefinition = $typeDefinition
        OutputType     = 'Library'
        OutputAssembly = $outputPath
    }
    Add-Type @params
}