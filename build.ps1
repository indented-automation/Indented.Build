#Requires -Module Configuration

[CmdletBinding()]
param(
    [ValidateSet('Build', 'Minor', 'Major')]
    [String]$ReleaseType = 'Build',

    [ValidateSet('Build', 'BuildTest', 'BuildRelease')]
    [String]$BuildType = 'Build',

    [String]$ModuleName,

    [String]$Nuget = (Resolve-Path "$psscriptroot\..\BuildTools\nuget.exe").Path,

    [String]$NugetRepository = '',

    [String]$NugetApiKey = $(if ($NugetRepository) { (Get-Content "$psscriptroot\..\BuildTools\nugetApiKey.txt" -Raw) })
)

#
# Self-update
#

if (Test-Path "$psscriptroot\..\BuildTools\build.ps1") {
    $source = "$psscriptroot\..\BuildTools\build.ps1"
    $destination = "$psscriptroot\build.ps1"

    if ((Get-Item $source).LastWriteTime -gt (Get-Item $destination).LastWriteTime) {
        Copy-Item $source $destination -Force
        & $destination @psboundparameters
        break
    }
}

#
# Build types
#

function Build {
    'Clean'
    'Pack'
    'Version'
    'ImportDependencies'
    'BuildClasses'
    'UpdateMetadata'
}
function BuildTest {
    Build
    
    'ImportTest'
    'PSScriptAnalyzer'
    'CodingConventions'
    'UnitTest'
    'CodeCoverage'
}
function BuildRelease {
    BuildTest

    'CreateGitHubRelease'
    'PublishModule'
}

#
# BuildInfo object shared across functions
#

$buildInfo = [PSCustomObject]@{
    ModuleName  = $ModuleName
    ReleaseType = $ReleaseType
    BuildType   = $BuildType
    Version     = '0.0.1'
    Repository  = $NugetRepository
    ApiKey      = $NugetApiKey
} | Add-Member 'Manifest' -MemberType ScriptProperty -Value { '{0}.psd1' -f $this.ModuleName } -PassThru |
    Add-Member 'RootModule' -MemberType ScriptProperty -Value { '{0}.psm1' -f $this.ModuleName } -PassThru
if (-not $ModuleName) {
    $buildInfo.ModuleName = (Get-Item $psscriptroot).Parent.GetDirectories((Split-Path $psscriptroot -Leaf)).Name
}

#
# Runner
#

function Invoke-BuildStep {
    param(
        [Parameter(ValueFromPipeline = $true)]
        $step
    )

    begin {
        $erroractionpreference = 'Stop'

        Push-Location $psscriptroot
    }
    
    process {
        $result = 'Success'
        $messageColour = 'Green'

        Write-Host $step.PadRight(30, ' ') -ForegroundColor Cyan -NoNewline

        $stopWatch = New-Object System.Diagnostics.StopWatch
        $stopWatch.Start()

        try {
            . $step
        } catch {
            $result = 'Fail'
            $messageColour = 'Red'

            throw
        } finally {
            $stopWatch.Stop()

            Write-Host -ForegroundColor $messageColour -Object $result.PadRight(10, ' ') -NoNewline
            Write-Host $stopWatch.Elapsed -ForegroundColor Gray

            if ($result -eq 'Fail') {
                Write-Host
            }
        }
    }

    end {
        Pop-Location
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
    [OutputType([System.Boolean])]
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
# Build steps
#

function Clean {
    if (Test-Path build\package) {
        Remove-Item build\package -Recurse -Force
    }
    $null = New-Item build\package -ItemType Directory -Force
}

function Pack {
    $path = [System.IO.Path]::Combine($pwd, 'build', 'package', $buildInfo.RootModule)

    Get-ChildItem 'source' -Exclude 'public', 'private', 'InitializeModule.ps1' |
        Copy-Item -Destination build\package -Recurse 

    $fileStream = New-Object System.IO.FileStream($path, 'Create')
    $writer = New-Object System.IO.StreamWriter($fileStream)

    Get-ChildItem 'source\public', 'source\private', 'InitializeModule.ps1' -Filter *.ps1 -Recurse | Where-Object Extension -eq '.ps1' | ForEach-Object {
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

function Version {
    $path = Join-Path 'source' $buildInfo.Manifest

    # Increment the version according to the release type.
    if (Test-Path $path) {
        $buildInfo.Version = Update-Metadata $path -Increment $buildInfo.ReleaseType -PassThru
        $buildInfo.ModuleName = (Get-Item 'source').GetFiles($buildInfo.Manifest).BaseName
    } else {
        $params = @{
            ModuleVersion = $Script:buildInfo.Version
        }
        New-ModuleManifest $path @params
    }
}

function ImportDependencies {
    # Import external dependencies listed in packages.config

    if (Test-Path 'packages.config') {
        if (Test-Path $Nuget) {
            $null = New-Item 'build\unpack' -ItemType Directory

            if (-not (Test-Path 'build\package\libraries')) {
                $null = New-Item 'build\package\libraries' -ItemType Directory
            }

            nuget restore -PackagesDirectory 'build\unpack'
            
            Get-ChildItem 'build\unpack' -Filter *.dll -Recurse | ForEach-Object {
                Copy-Item $_.FullName 'build\package\libraries'
            }

            Remove-Item 'build\unpack' -Recurse -Force
        } else {
            throw "Cannot merge external packages from packages.config without nuget.exe ($Nuget)"
        }
    }
}

function BuildClasses {
    # Build any C# classes and add them to required assemblies.
    
    if (Test-Path 'classes') {
        if (-not (Test-Path 'build\package\libraries')) {
            $null = New-Item 'build\package\libraries' -ItemType Directory
        }
        if (Test-Path 'classes\*.csproj') {
            Get-Item 'classes\*.csproj' | ForEach-Object {
                msbuild $_.FullName /t:rebuild
                Copy-Item 'classes\*.dll' 'build\package\libraries'
            }
        } else {
            Get-ChildItem 'classes' -Filter '*.cs' | ForEach-Object {
                $params = @{
                    TypeDefinition = Get-Content $_.FullName -Raw
                    Language       = 'CSharp'
                    OutputAssembly = "$psscriptroot\build\package\libraries\$($_.BaseName).dll"
                    OutputType     = 'Library'
                }

                if (Test-Path "classes\$($_.BaseName).ref") {
                    # Resolve the assembly list
                    $params.ReferencedAssemblies = Get-Content "classes\$($_.BaseName).ref" | ForEach-Object {
                        if (Test-Path "build\package\libraries\$_.dll") {
                            "$psscriptroot\build\package\libraries\$_.dll"
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

function UpdateMetadata {
    $path = [System.IO.Path]::Combine($pwd, 'build', 'package', $buildInfo.Manifest)

    # RootModule
    if (Enable-Metadata $path -PropertyName RootModule) {
        Update-Metadata $path -PropertyName RootModule -Value $buildInfo.RootModule
    }

    # FunctionsToExport
    if (Enable-Metadata $path -PropertyName FunctionsToExport) {
        Update-Metadata $path -PropertyName FunctionsToExport -Value (
            (Get-ChildItem 'source\public' -Filter '*.ps1' -File -Recurse).BaseName
        )
    }

    # RequiredAssemblies
    if (Test-Path 'build\package\libraries\*.dll') {
        if (Enable-Metadata $path -PropertyName RequiredAssemblies) {
            Update-Metadata $path -PropertyName RequiredAssemblies -Value (
                (Get-Item 'build\package\libraries\*.dll').Name | ForEach-Object {
                    Join-Path 'libraries' $_
                }
            )
        }
    }

    # FormatsToProcess
    if (Test-Path 'build\package\*.Format.ps1xml') {
        if (Enable-Metadata $path -PropertyName FormatsToProcess) {
            Update-Metadata $path -PropertyName FormatsToProcess -Value (Get-Item 'build\package\*.Format.ps1xml').Name
        }
    }

    # LicenseUri
    # if (Enable-Metadata $path -PropertyName LicenseUri) {
    #    Update-Metadata $path -PropertyName LicenseUri -Value 'https://opensource.org/licenses/MIT'
    # }

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

    $content = (Get-Content "source\$($buildInfo.Manifest)" -Raw).TrimEnd()
    Set-Content "source\$($buildInfo.Manifest)" -Value $content
}

function ImportTest {
    # Attempt to import the module, abort the build if the module does not import.
    # If the manifest declares a minimum version use PowerShell -version <version> to execute a best-effort test against that version

    $argumentList = @()
    $psVersion =  Get-Metadata "build\package\$($buildInfo.Manifest)" -PropertyName PowerShellVersion -ErrorAction SilentlyContinue 
    if ($null -ne $psVersion -and ([Version]$psVersion).Major -lt $psversionTable.PSVersion.Major) {
        $argumentList += '-Version', $psVersion
    }
    $argumentList += '-NoProfile', '-Command', ('
        try {{
            Import-Module ".\build\package\{0}" -Version "{1}" -ErrorAction Stop
        }} catch {{
            $_.Exception.Message
            exit 1
        }}
        exit 0
    ' -f $buildInfo.Manifest, $psVersion)

    & powershell.exe $argumentList
}

function PSScriptAnalyzer {
    # Execute PSScriptAnalyzer against the module.
    $i = 0
    Invoke-ScriptAnalyzer -Path "build\source\$($buildInfo.RootModule)" | ForEach-Object {
        $i++
        
        $_
    }
    if ($i -gt 0) {
        throw 'PSScriptAnalyzer tests are not clean'
    }
}

function CodingConventions {
    # Execute coding conventions tests using Pester.
    # Note: These tests are being executed against the Packaged module, not the code in the repository.

    if (-not (Test-Path 'build\pester')) {
        $null = New-Item 'build\pester' -ItemType Directory -Force
    }

    PowerShell.exe -NoProfile -Command "
        Import-Module '.\build\package\$($buildInfo.Manifest)' -ErrorAction Stop
        Invoke-Pester -Script '.\build\build_codingConventions.tests.ps1' -OutputFormat NUnitXml -OutputFile '.\build\pester\codingConventions.xml' -EnableExit
    "
}

function UnitTest {
    # Execute unit tests
    # Note: These tests are being executed against the Packaged module, not the code in the repository.

    if (-not (Test-Path 'build\pester')) {
        $null = New-Item 'build\pester' -ItemType Directory -Force
    }

    if (-not (Test-Path 'tests\unit\*')) {
        throw 'the project must have tests!'    
    }

    PowerShell.exe -NoProfile -Command "
        Import-Module '.\build\package\$($buildInfo.Manifest)' -ErrorAction Stop
        Invoke-Pester -Script 'tests\unit' -OutputFormat NUnitXml -OutputFile 'build\pester\Tests.xml' -EnableExit
    "
}

function CodeCoverage {
    # Exit if the code coverage falls below a certain value.
    # This executes all tests for a second time because:
    #   * It allows re-ordering.
    #   * It does not muddy the results of the UnitTest set.

    PowerShell.exe -NoProfile -Command "
        Import-Module '.\build\package\$($buildInfo.Manifest)' -ErrorAction Stop
        Invoke-Pester -Script 'tests\unit' -CodeCoverage '.\build\package\$($buildInfo.RootModule)' -Quiet -PassThru |
            Export-CliXml '.\build\pester\CodeCoverage.xml'
    "

    $pester = Import-CliXml '.\build\pester\CodeCoverage.xml'

    [Double]$codeCoverage = $pester.CodeCoverage.NumberOfCommandsExecuted / $pester.CodeCoverage.NumberOfCommandsAnalyzed
    $pester.CodeCoverage.MissedCommands | Export-Csv '.\temp\pester\CodeCoverage.csv' -NoTypeInformation

    Write-Host ('    CodeCoverage: {0:P2}. See build\pester\CodeCoverage.csv' -f $codeCoverage) -ForegroundColor Yellow

    if ($codecoverage -lt $CodeCoverageThreshold) {
        $message = 'Code coverage ({0:P}) is below threshold {1:P}.' -f $codeCoverage, $CodeCoverageThreshold 
        throw $message
    }
}

function CreateGitHubRelease {
    # Create a GitHub release and an associated tag.

    # Note quite complete.

    $tagName = 'v{0}' -f $buildInfo.Version
    $releaseName = '{0} {1}' -f $buildInfo.ModuleName, $tagName
    git tag -a $tagName -m ('Version {0}' -f $buildInfo.Version)
    if (git remote get-url --push origin) {
        git push origin $tagName
    }

    $gitUsername = git config user.name
    $release = Invoke-RestMethod -Method POST -Uri "https://api.github.com/repos/$gitUserName/$($buildInfo.ModuleName)/releases" -Body @{
        'tag_name'         = $tagName
        'target_commitish' = 'master'
        'name'             = $releaseName
    }

    $params = @{
        Method      = 'POST'
        Uri         = "https://api.github.com/repos/$gitUsername/$($buildInfo.ModuleName)/releases/$($release.id)/assets?name=$archiveName"
        ContentType = 'application/zip'
        Body        = (Get-Content $archiveName -Raw -Encoding Byte)
    }
    Invoke-RestMethod @params   
}

function PublishModule {
    # Publish the module to a repository. Publish-Module handles creating of the nupkg.

    if (-not $buildInfo.Repository) {
        throw 'A nuget repository must be defined'
    }
    if (-not $buildInfo.ApiKey) {
        throw 'Cannot publish a module without an API key'
    }
    $path = [System.IO.Path]::Combine('build', 'package', $buildInfo.Manifest)
    Publish-Module -Name $path -Repository $buildInfo.Repository -NuGetApiKey $buildInfo.ApiKey
}

#
# Main
#

Write-Host
Write-Host "Starting build"
Write-Host

try {
    & $BuildType | Invoke-BuildStep
} catch {
    Write-Error $_

    Write-Host
    Write-Host 'Build Failed!' -ForegroundColor Red
    Write-Host

    exit 1
}

Write-Host
Write-Host 'Build succeeded!' -ForegroundColor Green
Write-Host

exit 0