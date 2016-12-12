Properties {
    [String]$releaseType           = 'Build'
    [Double]$CodeCoverageThreshold = 0.8 # 80%

    [String]$projectPath           = Split-Path $psscriptroot -Parent
    [String]$moduleName            = Split-Path $projectPath -Leaf

    [String]$buildToolsPath        = (Resolve-Path "$psscriptroot\..\..\BuildTools").Path

    [String]$msbuildPath           = 'C:\windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe'

    [String]$nuGetRepository       = 'PSGallery'
    [String]$nuGetApiKey           = $(if ($nuGetRepository) { (Get-Content "$buildToolsPath\nugetApiKey.txt" -Raw) } else { '' } )
    [String]$nuGetPath             = (Resolve-Path "$buildToolsPath\nuget.exe").Path

    [Version]$version              = '0.0.0'
}

TaskSetup { 
    Push-Location $projectPath
}
TaskTearDown {
    Pop-Location
}

Task default -Depends Build
Task Build -Depends Setup, AddRequiredFiles, Clean, Version, CreateRelease, MergeModule, ImportDependencies, BuildClasses, UpdateMetadata
Task BuildTest -Depends Build, ImportTest, PSScriptAnalyzer, CodingConventions, UnitTest, CodeCoverage
Task UAT -Depends BuildTest, PushModule
Task Release -Depends BuildTest, PublishModule

#
# Task implementation
#

Task Setup {
    Assert (Test-Path $nugetPath) 'Nuget.exe must be available'
    Set-Alias nuget $nugetPath -Scope Global

    if (Test-Path $msbuildPath) {
        Set-Alias msbuild $msbuildPath -Scope Global
    }
}

Task Clean {
    # Delete all content in $Script:packagePath and recreate the directory.

    Get-ChildItem -Directory | Where-Object { $_.Name -as [Version] -or $_.Name -eq $temp } | Remove-Item -Recurse
}

Task AddRequiredFiles { 
    if (-not (Test-Path .gitignore) -or (Get-Item .gitignore).LastWriteTime -lt (Get-Item "$buildToolsPath\template\.gitignore").LastWriteTime) {
        Copy-Item "$buildToolsPath\template\.gitignore" .
    }
    if (-not (Test-Path LICENSE)) {
        Copy-Item "$buildToolsPath\template\LICENSE" .
    }
}

Task Version {
    # Increment the version according to the release type.
    if (-not (Test-Path "source\$moduleName.psd1")) {
        $params = @{
            Author        = "Chris Dent"
            CompanyName   = "Chris Dent"
            Copyright     = "(c) $((Get-Date).Year) Chris Dent"
            ModuleVersion = '0.0.1'
        }
        New-ModuleManifest "source\$moduleName.psd1" @params
    }

    $Script:version = Update-Metadata "source\$moduleName.psd1" -Increment $releaseType -PassThru
}

Task CreateRelease {
    # Create the shell of the module, static files and a manifest.

    if (-not (Test-Path $Script:version)) {
        $null = New-Item $Script:version -ItemType Directory
    }
    Get-ChildItem 'source' -Exclude 'public', 'private', '*.psm1', 'InitializeModule.ps1' | Copy-Item -Destination $Script:version -Recurse 
}

Task MergeModule {
    # Merge individual PS1 files into a single PSM1.
    
    # Use the same case as the manifest.
    $moduleName = (Get-Item "source\$moduleName.psd1").BaseName

    $fileStream = New-Object System.IO.FileStream("$projectPath\$Script:version\$moduleName.psm1", 'Create')
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
        $null = New-Item 'temp\unpack' -ItemType Directory

        if (-not (Test-Path "$Script:version\libraries")) {
            $null = New-Item "$Script:version\libraries" -ItemType Directory
        }

        nuget restore -PackagesDirectory 'temp\unpack'
        
        Get-ChildItem 'temp\unpack' -Filter *.dll -Recurse | ForEach-Object {
            Copy-Item $_.FullName "$Script:version\libraries"
        }

        Remove-Item 'temp\unpack' -Recurse -Force -Confirm:$false
    }
}

Task BuildClasses {
    # Build any C# classes and add them to required assemblies.
    
    if (Test-Path 'classes') {
        if (-not (Test-Path "$Script:version\libraries")) {
            $null = New-Item "$Script:version\libraries" -ItemType Directory
        }
        if (Test-Path 'classes\*.csproj') {
            Get-Item 'classes\*.csproj' | ForEach-Object {
                msbuild $_.FullName /t:rebuild
                Copy-Item 'classes\*.dll' "$Script:version\libraries"
            }
        } else {
            Get-ChildItem 'classes' -Filter '*.cs' | ForEach-Object {
                $params = @{
                    TypeDefinition = Get-Content $_.FullName -Raw
                    Language       = 'CSharp'
                    OutputAssembly = "$projectPath\$Script:version\libraries\$($_.BaseName).dll"
                    OutputType     = 'Library'
                }

                if (Test-Path "classes\$($_.BaseName).ref") {
                    # Resolve the assembly list
                    $params.ReferencedAssemblies = Get-Content "classes\$($_.BaseName).ref" | ForEach-Object {
                        if (Test-Path "$Script:version\libraries\$_.dll") {
                            "$projectPath\$Script:version\libraries\$_.dll"
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
    $path = "$Script:version\$moduleName.psd1"

    # RootModule
    if (Enable-Metadata $path -PropertyName RootModule) {
        Update-Metadata $path -PropertyName RootModule -Value "$moduleName.psm1"
    }  

    # FunctionsToExport
    if (Enable-Metadata $path -PropertyName FunctionsToExport) {
        Update-Metadata $path -PropertyName FunctionsToExport -Value (
            (Get-ChildItem 'source\public' -Filter '*.ps1' -File -Recurse).BaseName
        )
    }

    # RequiredAssemblies
    if (Test-Path "$Script:version\libraries\*.dll") {
        if (Enable-Metadata $path -PropertyName RequiredAssemblies) {
            Update-Metadata $path -PropertyName RequiredAssemblies -Value (
                (Get-Item "$Script:version\libraries\*.dll").Name | ForEach-Object {
                    Join-Path 'libraries' $_
                }
            )
        }
    }

    # FormatsToProcess
    if (Test-Path "$Script:version\*.Format.ps1xml") {
        if (Enable-Metadata $path -PropertyName FormatsToProcess) {
            Update-Metadata $path -PropertyName FormatsToProcess -Value (Get-Item "$Script:version\*.Format.ps1xml").Name
        }
    }

    # LicenseUri
    if (Enable-Metadata $path -PropertyName LicenseUri) {
        Update-Metadata $path -PropertyName LicenseUri -Value 'https://opensource.org/licenses/MIT'
    }

    # ProjectUri
    if (Enable-Metadata $path -PropertyName ProjectUri) {
        # Attempt to parse the project URI from the list of upstream repositories
        [String]$pushOrigin = (git remote -v) -like 'origin*(push)'
        if ($pushOrigin -match 'origin\s+(?<ProjectUri>\S+).git') {
            Update-Metadata $path -PropertyName ProjectUri -Value $matches.ProjectUri
        }
    }

    # Update-Metadata adds empty lines. Work-around to clean up all versions of the file.
    $content = (Get-Content $path -Raw).TrimEnd()
    Set-Content $path -Value $content

    $content = (Get-Content "source\$moduleName.psd1" -Raw).TrimEnd()
    Set-Content "source\$moduleName.psd1" -Value $content
}

# All testing is performed by invoking PowerShell because:
#   * It allows the use of the EnableExit parameter
#   * It works to avoids problems caused by file locks in the build directory 

Task ImportTest {
    # Attempt to import the module, abort the build if the module does not import.
    # If the manifest declares a minimum version use PowerShell -version <version> to execute a best-effort test against that version

    $argumentList = @()
    $psVersion =  Get-Metadata "$Script:version\$moduleName.psd1" -PropertyName PowerShellVersion -ErrorAction SilentlyContinue 
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
    ' -f $Script:version, $moduleName, $Script:version)

    exec { & powershell.exe $argumentList }
}

Task PSScriptAnalyzer {
    # Execute PSScriptAnalyzer against the module.
    $i = 0
    Invoke-ScriptAnalyzer -Path "$Script:version\$moduleName.psm1" | ForEach-Object {
        $i++
        
        $_
    }
    Assert ($i -eq 0) 'PSScriptAnalyzer tests are not clean'
}

Task CodingConventions {
    # Execute coding conventions tests using Pester.
    # Note: These tests are being executed against the Packaged module, not the code in the repository.

    if (-not (Test-Path 'temp\pester')) {
        $null = New-Item 'temp\pester' -ItemType Directory -Force
    }

    exec {
        PowerShell.exe -NoProfile -Command "
            Import-Module '.\$Script:version\$moduleName.psd1' -ErrorAction Stop
            Invoke-Pester -Script '.\build\build_codingConventions.tests.ps1' -OutputFormat NUnitXml -OutputFile '.\temp\pester\codingConventions.xml' -EnableExit
        "
    }
}

Task UnitTest {
    # Execute unit tests
    # Note: These tests are being executed against the Packaged module, not the code in the repository.

    if (-not (Test-Path 'temp\pester')) {
        $null = New-Item 'temp\pester' -ItemType Directory -Force
    }

    Assert ($null -ne (Get-ChildItem 'tests' -Recurse -Filter '*.tests.ps1')) 'The project must have tests!'

    exec {
        PowerShell.exe -NoProfile -Command "
            Import-Module '.\$Script:version\$moduleName.psd1' -ErrorAction Stop
            Invoke-Pester -Script 'tests' -OutputFormat NUnitXml -OutputFile 'temp\pester\Tests.xml' -EnableExit
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
            Import-Module '.\$Script:version\$moduleName.psd1' -ErrorAction Stop
            Invoke-Pester -Script 'tests' -CodeCoverage '.\$Script:version\$moduleName.psm1' -Quiet -PassThru |
                Export-CliXml '.\temp\pester\CodeCoverage.xml'
        "
    }

    $pester = Import-CliXml '.\temp\pester\CodeCoverage.xml'

    [Double]$codeCoverage = $pester.CodeCoverage.NumberOfCommandsExecuted / $pester.CodeCoverage.NumberOfCommandsAnalyzed
    $pester.CodeCoverage.MissedCommands | Export-Csv '.\temp\pester\CodeCoverage.csv' -NoTypeInformation

    Write-Host ('    CodeCoverage: {0:P2}. See temp\pester\CodeCoverage.csv' -f $codeCoverage) -ForegroundColor Cyan

    Assert ($codeCoverage -ge $CodeCoverageThreshold) ('Code coverage is below threshold {0:P}.' -f $CodeCoverageThreshold)
}

Task PushModule {
    # Push the module package to a list of devices for testing.
    # Just a file copy.

    $destination = "$($env:PSMODULEPATH.Split(';')[0])\$moduleName\$Script:version"
    $null = New-Item $destination -ItemType Directory -ErrorAction Stop
    Copy-Item "$Script:version\*" $destination -Recurse
}

Task PublishModule {
    # Publish the module to a repository. Publish-Module handles creating of the nupkg.

    if ($null -ne $nuGetRepository) {
        Publish-Module -Name "$projectPath\$Script:version\$moduleName.psd1" -Repository $nuGetRepository -NuGetApiKey $nugetApiKey
    }
}