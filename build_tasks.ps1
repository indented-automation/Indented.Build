Properties {
    $releaseType                   = 'Build'
    [Double]$CodeCoverageThreshold = 0.8 # 80%

    $projectPath                   = $psscriptroot
    $moduleName                    = Split-Path $psscriptroot -Leaf

    $msbuildPath                   = 'C:\windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe'

    $nuGetRepository               = 'PSGallery'
    $nuGetApiKey                   = $null
    $nuGetPath                     = "$psscriptroot\nuget.exe"

    $version                       = '0.0.0'
    $package                       = "package\$version"
}

Include '.\build_utils.ps1'

TaskSetup { 
    Push-Location $projectPath
}
TaskTearDown {
    Pop-Location
}

Task default -Depends Build
Task Build -Depends Setup, Clean, Version, CreatePackage, MergeModule, ImportDependencies, BuildClasses, UpdateMetadata
Task BuildTest -Depends Build, ImportTest, PSScriptAnalyzer, UnitTest, CodeCoverage
Task UAT -Depends BuildTest, PushModule
Task Release -Depends BuildTest, PublishModule

#
# Task implementation
#

Task Setup {
    Assert (Test-Path $nugetPath) 'Nuget.exe must be available'

    if ($nuGetRepository -ne 'PSGallery' -and $null -ne $nuGetRepository -and $null -eq $nuGetApiKey) {
        Assert (Test-Path "$psscriptroot\nuget.txt") 'Nuget API key must be available'
        $Script:nuGetApiKey = Get-Content "$psscriptroot\nuget.txt" -Raw
    }
    if (Test-Path $msbuildPath) {
        Set-Alias msbuild $msbuildPath -Scope Global
    }
    Set-Alias nuget $nugetPath -Scope Global
}

Task Clean {
    # Delete all content in $Script:packagePath and recreate the directory.
    if (Test-Path 'package' -PathType Container) {
        Remove-Item 'package' -Recurse -Force -Confirm:$false
    }
    $null = New-Item 'package' -ItemType Directory -Force
}

Task Version {
    # Increment the version according to the release type.
    $Script:version = Update-Metadata "source\$moduleName.psd1" -Increment $releaseType -PassThru
    $Script:package = "package\$Script:version"
}

Task CreatePackage {
    # Create the shell of the module, static files and a manifest.

    if (-not (Test-Path $Script:package)) {
        $null = New-Item $Script:package -ItemType Directory
    }
    Get-ChildItem 'source' -Exclude 'public', 'private', '*.psm1', 'InitializeModule.ps1' | Copy-Item -Destination $Script:package -Recurse 
}

Task MergeModule {
    # Merge individual PS1 files into a single PSM1.
    
    # Use the same case as the manifest.
    $moduleName = (Get-Item "source\$moduleName.psd1").BaseName

    $fileStream = New-Object System.IO.FileStream("$projectPath\$Script:package\$moduleName.psm1", 'Create')
    $writer = New-Object System.IO.StreamWriter($fileStream)

    Get-ChildItem 'source' -Filter *.ps1 -Recurse | Where-Object { $_.FullName -notlike "*source\examples*" -and $_.Extension -eq '.ps1' } | ForEach-Object {
        Get-Content $_.FullName | ForEach-Object {
            $writer.WriteLine($_.TrimEnd())
        }
        $writer.WriteLine()
    }

    if (Test-Path 'source\InitializeModule.ps1') {
        $writer.WriteLine('InitializeModule')
    }

    $writer.Close()
    $fileStream.Close()
}

Task ImportDependencies {
    if (Test-Path 'packages.config') {
        $null = New-Item 'package\unpack' -ItemType Directory

        if (-not (Test-Path "$Script:package\libraries")) {
            $null = New-Item "$Script:package\libraries" -ItemType Directory
        }

        nuget restore -PackagesDirectory 'package\unpack'
        
        Get-ChildItem 'package\unpack' -Filter *.dll -Recurse | ForEach-Object {
            Copy-Item $_.FullName "$Script:package\libraries"
        }

        Remove-Item 'package\unpack' -Recurse -Force -Confirm:$false
    }
}

Task BuildClasses {
    # Build any C# classes and add them to required assemblies.
    
    if (Test-Path 'classes') {
        if (-not (Test-Path "$Script:package\libraries")) {
            $null = New-Item "$Script:package\libraries" -ItemType Directory
        }
        if (Test-Path 'classes\*.csproj') {
            Get-Item 'classes\*.csproj' | ForEach-Object {
                msbuild $_.FullName /t:rebuild
                Copy-Item 'classes\*.dll' "$Script:package\libraries"
            }
        } else {
            Get-ChildItem 'classes' -Filter '*.cs' | ForEach-Object {
                $params = @{
                    TypeDefinition = Get-Content $_.FullName -Raw
                    Language       = 'CSharp'
                    OutputAssembly = "$projectPath\$Script:package\libraries\$($_.BaseName).dll"
                    OutputType     = 'Library'
                }

                if (Test-Path "classes\$($_.BaseName).ref") {
                    # Resolve the assembly list
                    $params.ReferencedAssemblies = Get-Content "classes\$($_.BaseName).ref" | ForEach-Object {
                        if (Test-Path "$Script:package\libraries\$_.dll") {
                            "$projectPath\$Script:package\libraries\$_.dll"
                        } else {
                            $_
                        }
                    }
                }
                Add-Type @params
            }
        }
    }
}

Task UpdateMetadata {
    $path = "$Script:package\$moduleName.psd1"

    # FunctionsToExport
    if (Enable-Metadata $path -PropertyName FunctionsToExport) {
        Update-Metadata $path -PropertyName FunctionsToExport -Value (
            (Get-ChildItem 'source\public' -Filter '*.ps1' -File -Recurse).BaseName
        )
    }

    # RequiredAssemblies
    if (Test-Path "$Script:package\libraries\*.dll") {
        if (Enable-Metadata $path -PropertyName RequiredAssemblies) {
            Update-Metadata $path -PropertyName RequiredAssemblies -Value (
                (Get-Item "$Script:package\libraries\*.dll").Name | ForEach-Object {
                    Join-Path 'libraries' $_
                }
            )
        }
    }

    # FormatsToProcess
    if (Test-Path "$Script:package\*.Format.ps1xml") {
        if (Enable-Metadata $path -PropertyName FormatsToProcess) {
            Update-Metadata $path -PropertyName FormatsToProcess -Value (Get-Item "$Script:package\*.Format.ps1xml").Name
        }
    }
}

# All testing is performed by invoking PowerShell because:
#   * It allows the use of the EnableExit parameter
#   * It works to avoids problems caused by file locks in the build directory 

Task ImportTest {
    # Attempt to import the module, abort the build if the module does not import.
    # If the manifest declares a minimum version use PowerShell -version <version> to execute a best-effort test against that version

    $argumentList = @()
    $psVersion =  Get-Metadata "$Script:package\$moduleName.psd1" -PropertyName PowerShellVersion -ErrorAction SilentlyContinue 
    if ($null -ne $psVersion -and ([Version]$psVersion).Major -lt $psversionTable.PSVersion.Major) {
        $argumentList += '-Version', $psVersion
    }
    $argumentList += '-NoProfile', '-Command', ('
        try {{
            Import-Module ".\{0}\{1}.psd1" -Version "{2}" -ErrorAction Stop
        }} catch {{
            $_.Exception.Message
            exit 1
        }}
        exit 0
    ' -f $Script:package, $moduleName, $Script:version)

    exec { & powershell.exe $argumentList }
}

Task PSScriptAnalyzer {
    # Execute PSScriptAnalyzer against the module.
    $i = 0
    Invoke-ScriptAnalyzer -Path "$Script:package\$moduleName.psm1" | ForEach-Object {
        $i++
        
        $_
    }
    if ($i -gt 0) {
        throw 'PSScriptAnalyzer tests are not clean'
    }
}

Task UnitTest {
    # Execute unit tests
    # This should die if there are no tests. No unit tests is bad.
    # Note: These tests are being executed against the Packaged module, not the code in the repository.

    if (-not (Test-Path 'package\pester')) {
        $null = New-Item 'package\pester' -ItemType Directory -Force
    }

    Assert ($null -ne (Get-ChildItem 'tests' -Recurse -Filter '*.tests.ps1')) 'The project must have tests!'

    exec {
        PowerShell.exe -NoProfile -Command "
            Import-Module '.\$Script:package\$moduleName.psd1' -ErrorAction Stop
            Invoke-Pester -Path 'tests' -OutputFormat NUnitXml -OutputFile 'package\pester\Tests.xml' -EnableExit
        "
    }
}

Task CodeCoverage {
    # Exit if the code coverage falls below a certain value.
    # This executes all tests for a second time because:
    #   * It allows re-ordering.
    #   * It does not muddy the results of the UnitTest set.

    exec {
        PowerShell.exe -NoProfile -Command "
            Import-Module '.\$Script:package\$moduleName.psd1' -ErrorAction Stop
            Invoke-Pester -Path 'tests' -CodeCoverage '.\$Script:package\$moduleName.psm1' -Quiet -PassThru |
                Export-CliXml '.\package\pester\CodeCoverage.xml'
        "
    }

    $pester = Import-CliXml '.\package\pester\CodeCoverage.xml'

    [Double]$codeCoverage = $pester.CodeCoverage.NumberOfCommandsExecuted / $pester.CodeCoverage.NumberOfCommandsAnalyzed
    $pester.CodeCoverage.MissedCommands | Export-Csv '.\package\pester\CodeCoverage.csv' -NoTypeInformation

    Write-Host ('    CodeCoverage: {0:P2}. See package\pester\CodeCoverage.csv' -f $codeCoverage) -ForegroundColor Cyan

    Assert ($codeCoverage -ge $CodeCoverageThreshold) ('Code coverage is below threshold {0:P}.' -f $CodeCoverageThreshold)
}

Task PushModule {
    # Push the module package to a list of devices for testing.
    # Just a file copy.

    $destination = "$($env:PSMODULEPATH.Split(';')[0])\$moduleName\$Script:version"
    $null = New-Item $destination -ItemType Directory -ErrorAction Stop
    Copy-Item "$Script:package\*" $destination -Recurse
}

Task PublishModule {
    # Publish the module to a repository. Publish-Module handles creating of the nupkg.

    if ($null -ne $nuGetRepository) {
        Publish-Module -Name "$projectPath\$Script:package\$moduleName.psd1" -Repository $Script:nuGetRepository # -NuGetApiKey $nuGetApiKey
    }
}
