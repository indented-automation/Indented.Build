BuildTask CompileClass -Stage Build -Order 3 -If {
    -not (Test-Path (Join-Path $buildInfo.Path.Source.Module 'class*\*.sln')) -and
    -not (Test-Path (Join-Path $buildInfo.Path.Source.Module 'class*\*.*proj')) -and
    (Test-Path (Join-Path $buildInfo.Path.Source.Module 'class*\*.cs'))
} -Definition {
    # If the class directory contains cs files, and does not contain proj or solution files, use Add-Type to generate a compiled assembly.

    try {
        Push-Location (Resolve-Path (Join-Path $buildInfo.Path.Source.Module 'class*')).Path

        $usingStatements = [System.Collections.Generic.HashSet[String]]::new()

        $params = @{
            Filter  = '*.cs'
            Recurse = $true
        }
        $typeDefinition = Get-ChildItem @params |
            Get-Content |
            ForEach-Object {
                if ($_ -match '^using ') {
                    $null = $usingStatements.Add($_)
                } else {
                    $_.TrimEnd()
                }
            } |
            Out-String

        if ($usingStatements.Count -gt 0) {
            $typeDefinition = $typeDefinition.Insert(
                0,
                ($buildInfo.Config.EndOfLineChar * 2)
            ).Insert(
                0,
                (($usingStatements | Sort-Object) -join $buildInfo.Config.EndOfLineChar)
            )
        }

        if (Test-Path 'classInfo.psd1') {
            $classInfo = Import-PowerShellDataFile 'classInfo.psd1'
        } else {
            $classInfo = @{}
        }
        if (-not $classInfo.Name) {
            $classInfo.Name = $buildInfo.ModuleName
        }

        if (Test-Path $buildInfo.Path.Build.RootModule) {
            $outputPath = Join-Path $buildInfo.Path.Build.Module.FullName 'lib'
            if (-not (Test-Path $outputPath)) {
                $null = New-Item $outputPath -ItemType Directory -Force
            }
        } else {
            $outputPath = $buildInfo.Path.Build.Module
        }

        $params = @{
            TypeDefinition = $typeDefinition
            OutputType     = 'Library'
            OutputAssembly = Join-Path $outputPath ('{0}.dll' -f $classInfo.Name)
        }
        if ($classInfo.ReferencedAssemblies) {
            $params.Add('ReferencedAssemblies', $classInfo.ReferencedAssemblies)
        }
        Add-Type @params
    } catch {
        throw
    } finally {
        Pop-Location
    }
}