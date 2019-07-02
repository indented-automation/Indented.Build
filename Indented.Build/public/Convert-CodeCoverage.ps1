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
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [PSObject]$CodeCoverage,

        [Parameter(Mandatory)]
        [PSTypeName('Indented.BuildInfo')]
        [PSObject]$BuildInfo
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
        }
    }
}