#Requires -Module Configuration, Pester

# TODO: Automatic step discovery
# TODO: Ability to update everything else in this script.

using namespace System.IO
using namespace System.Collections.Generic
using namespace System.Diagnostics
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Reflection

[CmdletBinding(DefaultParameterSetName = 'RunBuild')]
param(
    # The build type. Cannot use enum yet, it's not declared until this has executed.
    [Parameter(Position = 1)]
    [ValidateSet('Build', 'BuildTest', 'FunctionalTest', 'Release')]
    [String]$BuildType = 'Build',

    # The release type.
    [Parameter(Position = 2)]
    [ValidateSet('Build', 'Minor', 'Major')]
    [String]$ReleaseType = 'Build',

    # Return each the results of each build step as an object.
    [Parameter(ParameterSetName = 'RunBuild')]
    [Switch]$PassThru,

    # Return the BuildInfo object but do not run the build.
    [Parameter(ParameterSetName = 'GetInfo')]
    [Switch]$GetBuildInfo,

    # Suppress messages written by Write-Host.
    [Switch]$Quiet,

    # If IgnoreBuildChain is set the build script will execute steps declared in the BuildType. The default behaviour is to execute steps in the BuildType and all steps in earlier phases.
    [Switch]$IgnoreBuildChain
)

enum BuildType {
    Build          = 1
    BuildTest      = 2
    FunctionalTest = 3
    Release        = 4
}

[AttributeUsage([AttributeTargets]::Class, Inherited = $false)]
class BuildStep : Attribute {
    [BuildType] $BuildType
    [Int32] $Order = 255

    BuildStep([BuildType]$BuildType) {
        $this.BuildType = $BuildType
    }

    BuildStep([BuildType]$BuildType, [Int32]$Order) {
        $this.BuildType = $BuildType
        $this.Order = $Order
    }
}

class BuildInfo {
    # Fields / Properties

    # The name of the module being built.
    [String] $ModuleName = (Get-Item .).Parent.GetDirectories((Split-Path $pwd -Leaf)).Name

    # The version number of the build.
    [Version] $Version

    # The build type.
    [BuildType] $BuildType = 'Build'

    # The release type.
    [ValidateSet('Build', 'Minor', 'Major')]
    [String] $ReleaseType = 'Build'

    # The project folder.
    [DirectoryInfo] $Project = ((git rev-parse --show-toplevel) -replace '/', ([Path]::DirectorySeparatorChar))
    
    # The output directory.
    [DirectoryInfo] $Output
    
    # The generated module base path.
    [DirectoryInfo] $ModuleBase

    # The path to the root module.
    [FileInfo] $RootModule

    # The path to the manifest.
    [FileInfo] $Manifest

    # The root folder for the build activity.
    [String] $Build = $psscriptroot

    # Code coverage threshold.
    [Double] $CodeCoverageThreshold = 0.9

    # Whether or not this script has self-updated. Get only.
    [Boolean] $StepsUpdated = $false

    # Execute steps and predecessor steps, or steps in this BuildType only.
    [Boolean] $IgnoreBuildChain = $false

    # Whether or not the script can update itself. Get only.
    hidden [Boolean] $CanUpdate = $false

    # Whether or not the script should update itself. Get or Set.
    hidden [Boolean] $ShouldUpdate = $true

    # Cache the results of self-analysis.
    hidden $cachedSteps = (New-Object List[PSObject])

    # Constructors

    BuildInfo($BuildType, $ReleaseType) {
        $this.BuildType = $BuildType
        $this.ReleaseType = $ReleaseType

        $this.ImportBuildMetadata()
        $this.Version = $this.GetBuildVersion()
        $this.SetPaths()

        if (Get-Module Indented.Build -ListAvailable) {
            $this.CanUpdate = $true
        }

        # Should update can be disabled in this script or in buildMetadata.
        if ($this.ShouldUpdate) {
            foreach ($step in $this.GetSteps()) {
                $this.UpdateStep($step.Name)
            }
        }
    }

    # Public methods

    [Void] AddStep([String]$StepName) {
        if ($this.CanUpdate) {
            $scriptContent = Get-Content $pscommandpath -Raw
            $steps = @()
            $startOffset = 0

            if ($this.GetSteps().Count -gt 0 -and -not $this.GetStep($StepName)) {
                # Re-order things into the same order as GetSteps(BuildType).
                
                $startOffset = $this.cachedSteps[0].StartOffset
                $scriptContent = $scriptContent.Remove(
                    $startOffset,
                    $this.cachedSteps[-1].EndOffset - $startOffset
                )

                $steps = $this.cachedSteps.ToArray() + @(Get-BuildStep $StepName) |
                    Sort-Object { $_.BuildStep.BuildType }, { $_.BuildStep.Order }, Name
            } elseif ($this.cachedSteps.Count -eq 0) {
                $startOffset = $scriptContent.LastIndexOf('# Steps') + ("# Steps`r`n".Length)
                $scriptContent = $scriptContent.Insert($startOffset, "`r`n`r`n")
                $startOffset += 2

                $steps = @(Get-BuildStep $StepName)
            }

            if ($steps.Count -gt 0) {
                $scriptContent = $scriptContent.Insert($startOffset, ($steps.Definition -join "`r`n`r`n"))
                Set-Content -Path $pscommandpath -Value $scriptContent -NoNewline

                $this.StepsUpdated = $true
            }
        }
    }

    # Return a step exactly matching a name.
    [PSObject] GetStep([String]$StepName) {
        return $this.GetSteps() | Where-Object Name -eq $StepName
    }

    # Return an ordered list of steps based on the BuildInfo BuildType attribute
    # then the step name.
    [PSObject[]] GetSteps([String]$BuildType) {
        return $this.GetSteps() |
            Where-Object { 
                ($this.IgnoreBuildChain -and $_.BuildStep.BuildType -eq [BuildType]$this.BuildType) -or
                (-not $this.IgnoreBuildChain -and $_.BuildStep.BuildType -le [BuildType]$this.BuildType)
            } |
            Sort-Object { $_.BuildStep.BuildType }, { $_.BuildStep.Order }, Name
    }

    [PSObject[]] GetSteps() {
        if ($this.cachedSteps.Count -eq 0) {
            $tokens = $parseErrors = $null
            $ast = [Parser]::ParseFile(
                $pscommandpath,
                [Ref]$tokens,
                [Ref]$parseErrors
            )

            $ast.FindAll( {
                    param( $ast )
                    
                    $ast -is [FunctionDefinitionAst] -and 
                    $ast.Name -notlike '*-*' -and 
                    $ast.Parent -is [NamedBlockAst] -and
                    ($ast.Body.ParamBlock.Attributes | Where-Object { $_.TypeName.ToString() -eq 'BuildStep' }) 
                },
                $false
            ) | ForEach-Object {
                # There's a scope problem here. BuildStep needs to be available or it won't parse.
                # Might be able to do something about this if the executionContext is tweaked in Get-FunctionInfo.
                $this.cachedSteps.Add((
                    [PSCustomObject]@{
                        Name        = $_.Name
                        Definition  = $_.ToString()
                        StartOffset = $_.Extent.StartOffset
                        EndOffset   = $_.Extent.EndOffset
                        Length      = $_.Extent.EndOffset - $_.Extent.StartOffset
                        BuildStep   = (Get-Command $_.Name).ScriptBlock.Attributes |
                            Where-Object { $_ -is [BuildStep] }
                    }
                ))
            }
        }
        return $this.cachedSteps.ToArray()
    }

    [Void] UpdateStep([String]$StepName) {
        if ($this.CanUpdate) {
            $step = $this.GetStep($StepName)
            if ($step.Definition) {
                $newStep = Get-BuildStep $StepName

                if ($step.Definition -ne $newStep.Definition) {
                    $scriptContent = Get-Content $pscommandpath -Raw
                    $scriptContent = $scriptContent.Remove(
                                        $step.StartOffset,
                                        $step.Length
                                    ).Insert(
                                        $step.StartOffset,
                                        $newStep.Definition
                                    )
                    Set-Content -Path $pscommandpath -Value $scriptContent -NoNewline

                    $this.StepsUpdated = $true
                }
            } else {
                # Invalid argument.
                throw ('Unable to find step named {0} to update.' -f $StepName)
            }
        }
    }

    # Private methods

    hidden [Version] GetBuildVersion() {
        # Generate version numbers
        $sourceManifest = [Path]::Combine($this.Build, 'source', ('{0}.psd1' -f $this.ModuleName))
        if (Test-Path $sourceManifest) {
            [Version]$currentVersion = Get-Metadata -Path $sourceManifest -PropertyName ModuleVersion
            $buildVersion = switch ($this.ReleaseType) {
                'Build' {
                    $buildNumber = $currentVersion.Build
                    if ($currentVersion.Build -eq -1) {
                        $buildNumber = 0
                    }
                    New-Object Version($currentVersion.Major, $currentVersion.Minor, ($buildNumber + 1))
                }
                'Major' { New-Object Version(($currentVersion.Major + 1), 0) }
                'Minor' { New-Object Version($currentVersion.Major, ($currentVersion.Minor + 1)) }
                default { [Version]'0.0.1' }
            }
            return $buildVersion
        } else {
            return [Version]'0.0.1'
        }
    }

    hidden [Void] ImportBuildMetadata() {
        if (Test-Path .\buildMetadata.psd1) {
            $buildMetadata = ConvertFrom-Metadata .\buildMetadata.psd1
            foreach ($key in $buildMetadata.Keys) {
                if ($this.$key -and $this.$key -ne $buildMetadata.$key) {
                    $this.$key = $buildMetadata.$key
                }
            }
        }
    }


    hidden [Void] SetPaths() {
        if ((Split-Path $this.Project -Leaf) -eq $this.ModuleName) {
            $base = $this.Project
        } else {
            $base = Join-path $this.Project $this.ModuleName
        }

        $this.Output = Join-Path $base 'output'
        $this.ModuleBase = Join-Path $base $this.Version
        $this.RootModule = New-Object FileInfo(Join-Path $this.ModuleBase ('{0}.psm1' -f $this.ModuleName))
        $this.Manifest = New-Object FileInfo(Join-Path $this.ModuleBase ('{0}.psd1' -f $this.ModuleName))
    }
}

# Supporting functions

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
        } catch [ItemNotFoundException] {
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
        $ast = [Parser]::ParseInput(
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

function Invoke-Step {
    # .SYNOPSIS
    #   Invoke a build step.
    # .DESCRIPTION
    #   An output display wrapper to show progress through a build.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Object
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     01/02/2017 - Chris Dent - Added help.
    
    param(
        [Parameter(ValueFromPipeline = $true)]
        $StepName
    )

    begin {
        $stopWatch = New-Object StopWatch
    }
    
    process {
        $progressParams = @{
            Activity = 'Building {0} ({1})' -f $this.ModuleName, $this.Version
            Status   = 'Executing {0}' -f $StepName
        }
        Write-Progress @progressParams

        $stepInfo = [PSCustomObject]@{
            Name      = $StepName
            Result    = 'Success'
            StartTime = [DateTime]::Now
            TimeTaken = $null
            Errors    = $null
        }
        $messageColour = 'Green'
        
        $stopWatch = New-Object System.Diagnostics.StopWatch
        $stopWatch.Start()

        try {
            if (Get-Command $StepName -ErrorAction SilentlyContinue) {
                & $StepName
            } else {
                $stepInfo.Errors = 'InvalidStep'
            }
        } catch {
            $stepInfo.Result = 'Failed'
            $stepInfo.Errors = $_
            $messageColour = 'Red'
        }

        $stopWatch.Stop()
        $stepInfo.TimeTaken = $stopWatch.Elapsed

        if (-not $Quiet) {
            Write-Host $StepName.PadRight(30) -ForegroundColor Cyan -NoNewline
            Write-Host -ForegroundColor $messageColour -Object $stepInfo.Result.PadRight(10) -NoNewline
            Write-Host $stepInfo.StartTime.ToString('t').PadRight(10) -ForegroundColor Gray -NoNewLine
            Write-Host $stepInfo.TimeTaken -ForegroundColor Gray
        }

        return $stepInfo
    }
}

function Write-Message {
    param(
        [String]$Object,

        [ConsoleColor]$ForegroundColor,

        [Switch]$Quiet
    )

    $null = $psboundparameters.Remove('Quiet')
    if (-not $Quiet) {
        Write-Host
        Write-Host @psboundparameters
        Write-Host
    }
}

# Steps

# Run the build

try {
    Push-Location $psscriptroot

    $buildInfo = New-Object BuildInfo($BuildType, $ReleaseType)
    if ($IgnoreBuildChain) {
        $buildInfo.IgnoreBuildChain = $true
    }
    if ($buildInfo.StepsUpdated) {
        & $pscommandpath @psboundparameters
    } else {
        if ($GetBuildInfo) {
            return $buildInfo
        } else {
            $quietParam = @{}
            if ($Quiet) {
                $quietParam.Quiet = $true
            }

            Write-Message ('Building {0} ({1})' -f $buildInfo.ModuleName, $buildInfo.Version) @quietParam
            
            foreach ($step in $buildInfo.GetSteps($BuildType)) {
                $stepInfo = Invoke-Step $step.Name

                if ($PassThru) {
                    $stepInfo
                }

                if ($stepInfo.Result -ne 'Success') {
                    throw $stepinfo.Errors
                }
            }

            Write-Message "Build succeeded!" -ForegroundColor Green @quietParam

            $lastexitcode = 0
        }
    }
} catch {
    Write-Message 'Build Failed!' -ForegroundColor Red @quietParam

    $lastexitcode = 1

    # Catches unexpected errors, rethrows errors raised while executing steps.
    throw
} finally {
    Pop-Location
}