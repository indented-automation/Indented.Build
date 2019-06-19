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
            Get-MethodInfo |
            Group-Object FullName -AsHashTable

        $sourceClasses = $BuildInfo |
            Get-BuildItem -Type ShouldMerge |
            Get-MethodInfo |
            Group-Object FullName -AsHashTable
    }

    process {
        foreach ($category in 'MissedCommands', 'HitCommands') {
            foreach ($command in $CodeCoverage.$category) {
                if ($command.Class) {
                    $name = '{0}\{1}' -f $command.Class, $command.Function

                    if ($buildClasses.ContainsKey($name)) {
                        $buildExtent = $buildClasses[$name].Extent
                        $sourceExtent = $sourceClasses[$name].Extent
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