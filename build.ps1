#requires -Module psake, Configuration, pester

Properties {
    $releaseType                   = 'Build'
    [Double]$CodeCoverageThreshold = 0.8 # 80%

    $projectPath                   = $psscriptroot
    $moduleName                    = Split-Path $psscriptroot -Leaf

    $nuGetRepository               = 'LocalRepo'
    $nuGetApiKey                   = (Get-Content 'C:\Dev\PowerShell\buildtools\nuget.txt' -Raw)
    $nuGetPath                     = "C:\Dev\PowerShell\buildtools\nuget.exe"

    $version                       = '0.0.0'
    $package                       = "package\$version"
}

$commonParams = @{
    PreAction  = { Push-Location $projectPath }
    PostAction = { Pop-Location }
}

Task default -Depends Build
Task Build -Depends Setup, Clean, Version, CreatePackage, MergeModule, ImportDependencies, BuildClasses, UpdateMetadata
Task BuildTest -Depends Build, PSScriptAnalyzer, ImportTest, UnitTest, CodeCoverage, IntegrationTest
Task UAT -Depends BuildTest, PushModule
Task Release -Depends BuildTest, PublishModule

#
# Supporting functions
#

function ConvertTo-Hashtable {
    # A very short function to convert a PSObject into a Hashtable. Generates splattable params.

    param(
        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$PSObject
    )

    process {
        $hashtable = @{}
        foreach ($property in $PSObject.PSObject.Properties) {
            $hashtable.($property.Name) = $property.Value
        }
        $hashtable
    }
}

function Enable-Metadata {
    # .SYNOPSIS
    #   Enable a metadata property which has been commented out.
    # .DESCRIPTION
    #   This function is derived Get and Update-Metadata from PoshCode\Configuration.
    #
    #   A boolean value is returned indicating if the property is available in the metadata file.
    # .PARAMETER Path
    #   A valid metadata file or string containing the metadata.
    # .PARAMETER PropertyName
    #   The property to enable.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Boolean
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     04/08/2016 - Chris Dent - Created.

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [Alias("PSPath")]
        [String]$Path,

        [String]$PropertyName
    )

    process {
        # If the element can be found using Get-Metadata leave it alone and return true
        $shouldCreate = $false
        try {
            $null = Get-Metadata @psboundparameters -ErrorAction Stop
        } catch [System.Management.Automation.ItemNotFoundException] {
            # The function will only execute where the requested value is not present
            $shouldCreate = $true
        } catch {
            # Ignore other errors which may be raised by Get-Metadata except path not found.
            if ($_.Exception.Message -eq 'Path must point to a .psd1 file') {
                $pscmdlet.ThrowTerminatingError($_)
            }
        }
        if (-not $shouldCreate) {
            return $true
        }

        $manifestContent = Get-Content $Path -Raw
    
        $tokens = $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            $manifestContent,
            $Path,
            [Ref]$tokens,
            [Ref]$parseErrors
        )

        # Attempt to find a comment which matches the requested property
        $regex = '^ *# *({0}) *=' -f $PropertyName
        $existingValue = @($tokens | Where-Object { $_.Kind -eq 'Comment' -and $_.Text -match $regex })
        if ($existingValue.Count -eq 1) {
            $manifestContent = $ast.Extent.Text.Remove(
                $existingValue.Extent.StartOffset,
                $existingValue.Extent.EndOffset - $existingValue.Extent.StartOffset
            ).Insert(
                $existingValue.Extent.StartOffset,
                $existingValue.Extent.Text -replace '^# *'
            )

            try {
                Set-Content $Path $manifestContent -NoNewLine -ErrorAction Stop
            } catch {
                return $false
            }
            return $true
        } elseif ($existingValue.Count -eq 0) {
            # Item not found
            Write-Verbose "Can't find disabled property '$PropertyName' in $Path"
            return $false
        } else {
            # Ambiguous match
            Write-Verbose "Found more than one '$PropertyName' in $Path"
            return $false
        }
    }
}

#
# Task implementation
#

Task Setup @commonParams {
    if (Test-Path $nugetPath) {
        Set-Alias nuget $nugetPath -Scope Global
    } else {
        throw 'Nuget.exe must be available'
    }
}

Task Clean @commonParams {
    # Delete all content in $Script:packagePath and recreate the directory.
    if (Test-Path 'package' -PathType Container) {
        Remove-Item 'package' -Recurse -Force -Confirm:$false
    }
    $null = New-Item 'package' -ItemType Directory -Force
}

Task Version @commonParams {
    # Increment the version according to the release type.
    $Script:version = Update-Metadata "source\$moduleName.psd1" -Increment $releaseType -PassThru
    $Script:package = "package\$Script:version"
}

Task CreatePackage @commonParams {
    # Create the shell of the module, static files and a manifest.

    if (-not (Test-Path $Script:package)) {
        $null = New-Item $Script:package -ItemType Directory
    }
    Get-ChildItem 'source' -Exclude 'public', 'private', '*.psm1', 'InitializeModule.ps1' | Copy-Item -Destination $Script:package -Recurse 
}

Task MergeModule @commonParams {
    # Merge individual PS1 files into a single PSM1.
    
    # Use the same case as the manifest.
    $moduleName = (Get-Item "source\$moduleName.psd1").BaseName

    $fileStream = New-Object System.IO.FileStream("$projectPath\$Script:package\$moduleName.psm1", 'Create')
    $writer = New-Object System.IO.StreamWriter($fileStream)

    Get-ChildItem 'source' -Filter *.ps1 -Recurse | Where-Object { $_.FullName -notlike "*source\examples*" } | ForEach-Object {
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

Task ImportDependencies @commonParams {
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

Task BuildClasses @commonParams {
    # Build any C# classes and add them to required assemblies.
    
    if (Test-Path 'classes') {
        if (-not (Test-Path "$Script:package\libraries")) {
            $null = New-Item "$Script:package\libraries" -ItemType Directory
        }

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

Task UpdateMetadata @commonParams {
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

Task PSScriptAnalyzer @commonParams {
    # Execute PSScriptAnalyzer against the module.
    
}

Task ImportTest @commonParams {
    # Attempt to import the module, abort the build if the module does not import.
    # If the manifest declares a minimum version use PowerShell -version <version> to execute a best-effort test against that version

    $argumentList = @()

    $psVersion =  Get-Metadata "$Script:package\$moduleName.psd1" -PropertyName PowerShellVersion -ErrorAction SilentlyContinue 
    if ($null -ne $psVersion) {
        $argumentList += '-Version', $psVersion
    }
    $argumentList += '-Command', "
        try {
            Import-Module '$Script:package\$moduleName.psd1' -Version '$Script:version' -ErrorAction Stop
        } catch {
            $_.Exception.Message
            exit 1
        }
        exit 0
    "

    $errorMessage = & powershell.exe $argumentList

    if ($lastexitcode -gt 0) {
        throw ('Failed to load module ({0})' -f $errorMessage)
    }
}

Task UnitTest @commonParams {
    # Execute unit tests
    # This should die if there are no tests. No unit tests is bad.
    # Note: These tests are being executed against the Packaged module, not the code in the repository.

    if (-not (Test-Path 'package\pester')) {
        $null = New-Item 'package\pester' -ItemType Directory -Force
    }

    PowerShell.exe -Command "
        Import-Module '$Script:package\$moduleName.psd1' -ErrorAction Stop
        Invoke-Pester -Path 'tests\unit' -OutputFormat NUnitXml -OutputFile 'package\pester\UnitTests.xml' -EnableExit
    "

    if ($lastexitcode -gt 0) {
        throw ('Failed {0} unit tests' -f $lastexitcode)
    }
}

Task CodeCoverage @commonParams {
    # Exit if the code coverage falls below a certain value.
    # This executes all tests for a second time because:#
    #   * It allows re-ordering.
    #   * It does not muddy the results of the UnitTest set.

    $pester = PowerShell.exe -Command "
        Import-Module '$Script:package\$moduleName.psd1' -ErrorAction Stop
        Invoke-Pester -Path 'tests\unit' -CodeCoverage '$Script:package\$moduleName.psm1' -PassThru |
            Export-CliXml 'package\pester\CodeCoverage.xml'
    "

    $pester = Import-CliXml "package\pester\CodeCoverage.xml"

    [Double]$codeCoverage = $pester.CodeCoverage.NumberOfCommandsExecuted / $pester.CodeCoverage.NumberOfCommandsAnalyzed

    if ($codeCoverage -lt $CodeCoverageThreshold) {
        $pester.CodeCoverage.MissedCommands | Export-Csv 'package\pester\CodeCoverage.csv' -NoTypeInformation

        throw ('Code coverage is below threshold {0:P}. See package\pester\CodeCoverage.csv' -f $CodeCoverageThreshold)
    }
}

Task IntegrationTest @commonParams {
    # Integration tests may be included but are optional.
    
    if (Test-Path 'tests\integration') {
        PowerShell.exe -Command "
            Import-Module '$Script:package\$moduleName.psd1' -ErrorAction Stop
            Invoke-Pester -Path 'tests\integration' -OutputFormat NUnitXml -OutputFile 'package\pester\IntegrationTests.xml' -EnableExit
        "

        if ($lastexitcode -gt 0) {
            throw ('Failed {0} integration tests' -f $lastexitcode)
        }
    }
}

Task PushModule @commonParams {
    # Push the module package to a list of devices for testing.
    # Just a file copy.

    $destination = "$($env:PSMODULEPATH.Split(';')[0])\$moduleName\$Script:version"
    $null = New-Item $destination -ItemType Directory -ErrorAction Stop
    Copy-Item "$Script:package\*" $destination -Recurse
}

Task PublishModule @commonParams {
    # Publish the module to a repository. Publish-Module handles creating of the nupkg.

    Publish-Module -Name "$projectPath\$Script:package\$moduleName.psd1" -Repository $nuGetRepository -NuGetApiKey $nuGetApiKey
}
