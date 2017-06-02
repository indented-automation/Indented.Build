filter Start-Build {
    <#
    .SYNOPSIS
        Start a build.
    .DESCRIPTION
        Start a build using Invoke-Build. If a build script is not present one will be created.

        If a build script exists it will be used. If the build script exists this command is superfluous.
    #>

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
    [CmdletBinding()]
    [OutputType([Void])]
    param (
        # The task categories to execute.
        [String[]]$BuildType = @('Setup', 'Build', 'Test'),

        # The release type to create.
        [ValidateSet('Build', 'Minor', 'Major')]
        [String]$ReleaseType = 'Build',

        [Parameter(ValueFromPipeline = $true)]
        [PSTypeName('BuildInfo')]
        [PSObject]$BuildInfo = (Get-BuildInfo -BuildType $BuildType -ReleaseType $ReleaseType),

        [String]$ScriptName = '.build.ps1'
    )

    try {
        # If a build script exists in the project root, use it.
        if (Test-Path (Join-Path $buildInfo.Path.ProjectRoot $ScriptName)) {
            $buildScript = Join-Path $buildInfo.Path.ProjectRoot $ScriptName
        } else {
            # Otherwise assume the project contains more than one module and create a module specific script.
            $buildScript = Join-Path $buildInfo.Path.Source $ScriptName
        }

        # Remove the script if it is created by this process. Export-BuildScript can be used to create a persistent script.
        $shouldClean = $false
        if (-not (Test-Path $buildScript)) {
            $BuildInfo | Export-BuildScript -Path $buildScript
            $shouldClean = $true
        }

        Invoke-Build -Task $BuildType -File $buildScript
    } catch {
        throw
    } finally {
        if ($shouldClean) {
            Remove-Item $buildScript
        }
    }
}