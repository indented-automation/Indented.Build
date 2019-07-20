function Convert-CodeCoverage {
    <#
    .SYNOPSIS
        Converts code coverage line and file reference from root module to file.
    .DESCRIPTION
        When tests are executed against a merged module, all lines are relative to the psm1 file.

        This command updates line references to match the development file set.
    #>

    [CmdletBinding()]
    param (
        # The original code coverage report.
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [PSObject]$CodeCoverage,

        # The output from Get-BuildInfo for this project.
        [Parameter(Mandatory)]
        [PSTypeName('Indented.BuildInfo')]
        [PSObject]$BuildInfo,

        # Write missed commands using format table as they are discovered.
        [Switch]$Tee
    )

    begin {
        $buildFunctions = $BuildInfo.Path.Build.RootModule |
            Get-FunctionInfo |
            Group-Object Name -AsHashTable

        $sourceFunctions = $BuildInfo |
            Get-BuildItem -Type ShouldMerge |
            Get-FunctionInfo |
            Group-Object Name -AsHashTable

        $buildClasses = $BuildInfo.Path.Build.RootModule |
            Get-ClassInfo |
            Group-Object Name -AsHashTable

        $sourceClasses = $BuildInfo |
            Get-BuildItem -Type ShouldMerge |
            Get-ClassInfo |
            Group-Object Name -AsHashTable
    }

    process {
        foreach ($category in 'MissedCommands', 'HitCommands') {
            foreach ($command in $CodeCoverage.$category) {
                if ($command.Class) {
                    if ($buildClasses.ContainsKey($command.Class)) {
                        $buildExtent = $buildClasses[$command.Class].Extent
                        $sourceExtent = $sourceClasses[$command.Class].Extent
                    }
                } else {
                    if ($buildFunctions.Contains($command.Function)) {
                        $buildExtent = $buildFunctions[$command.Function].Extent
                        $sourceExtent = $sourceFunctions[$command.Function].Extent
                    }
                }

                if ($buildExtent -and $sourceExtent) {
                    $command.File = $sourceExtent.File

                    $command.StartLine = $command.Line = $command.StartLine -
                        $buildExtent.StartLineNumber +
                        $sourceExtent.StartLineNumber

                    $command.EndLine = $command.EndLine -
                        $buildExtent.StartLineNumber +
                        $sourceExtent.StartLineNumber
                }
            }

            if ($Tee -and $category -eq 'MissedCommands') {
                $CodeCoverage.$category | Format-Table @(
                    @{ Name = 'File'; Expression = {
                        if ($_.File -eq $buildInfo.Path.Build.RootModule) {
                            $buildInfo.Path.Build.RootModule.Name
                        } else {
                            ($_.File -replace ([Regex]::Escape($buildInfo.Path.Source.Module))).TrimStart('\')
                        }
                    }}
                    @{ Name = 'Name'; Expression = {
                        if ($_.Class) {
                            '{0}\{1}' -f $_.Class, $_.Function
                        } else {
                            $_.Function
                        }
                    }}
                    'Line'
                    'Command'
                )
            }
        }
    }
}