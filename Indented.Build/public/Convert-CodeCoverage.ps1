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
        $module = $buildInfo.Path.Build.RootModule |
            Get-FunctionInfo |
            Group-Object Name -AsHashTable

        $functions = $BuildInfo |
            Get-BuildItem -Type ShouldMerge |
            Get-FunctionInfo |
            Group-Object Name -AsHashTable
    }

    process {
        foreach ($category in 'MissedCommands', 'HitCommands') {
            foreach ($command in $CodeCoverage.$category) {
                $command.File = $functions[$command.Function].Extent.File

                $command.StartLine = $command.Line = $command.StartLine -
                                     $module[$command.Function].Extent.StartLineNumber +
                                     $functions[$command.Function].Extent.StartLineNumber

                $command.EndLine = $command.EndLine -
                                   $module[$command.Function].Extent.StartLineNumber +
                                   $functions[$command.Function].Extent.StartLineNumber
            }
        }
    }
}