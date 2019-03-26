function New-ConfigDocument {
    <#
    .SYNOPSIS
        Create a new build configuration document
    .DESCRIPTION
        The build configuration document may be used to adjust the configurable build values for a single module.
    #>

    [CmdletBinding(DefaultParameterSetName = 'UsingPath')]
    param (
        # The path to the  buildConfig.psd1 document.
        [Parameter(Mandatory, ParameterSetName = 'UsingPath')]
        [ValidateScript( {
            if (Test-Path $_ -PathType Container) {
                $true
            } else {
                throw 'Path must be an existing directory'
            }
        } )]
        [String]$Path,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromBuildInfo')]
        [PSTypeName('Indented.BuildInfo')]
        $BuildInfo
    )

    process {
        if ($BuildInfo) {
            $documentPath = Join-Path $BuildInfo.Path.Source.Module 'buildConfig.psd1'
        } else {
            $documentPath = Join-Path $Path 'buildConfig.psd1'
        }

        $eolChar = switch -Regex ([Environment]::NewLine) {
            '\r\n' { '`r`n' }
            '\n'   { '`n' }
            '\r'   { '`r' }
        }

        # Build configuration for Indented.Build
        @(
            '@{'
            '    CodeCoverageThreshold = 0.8'
            ('    EndOfLineChar         = "{0}"' -f $eolChar)
            "    License               = 'MIT'"
            '    CreateChocoPackage    = $false'
            '}'
        ) | Set-Content -Path $documentPath
    }
}