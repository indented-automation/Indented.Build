function Build-Module {
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
    param (
        # The task categories to execute.
        [String[]]$BuildType = ('Setup', 'Build', 'Test'),

        # The release type to create.
        [ValidateSet('Build', 'Minor', 'Major', 'None')]
        [String]$ReleaseType = 'Build',

        [Parameter(ValueFromPipeline)]
        [PSTypeName('Indented.BuildInfo')]
        [PSObject[]]$BuildInfo = (Get-BuildInfo),

        [String]$ScriptName = '.build.ps1'
    )

    foreach ($instance in $BuildInfo) {
        try {
            # If a build script exists in the project root, use it.
            if (Test-Path (Join-Path $instance.Path.ProjectRoot $ScriptName)) {
                $buildScript = Join-Path $instance.Path.ProjectRoot $ScriptName
            } else {
                # Otherwise assume the project contains more than one module and create a module specific script.
                $buildScript = Join-Path $instance.Path.Source $ScriptName
            }

            # Remove the script if it is created by this process. Export-BuildScript can be used to create a persistent script.
            $shouldClean = $false
            if (-not (Test-Path $buildScript)) {
                $instance | Export-BuildScript -Path $buildScript
                $shouldClean = $true
            }

            Import-Module InvokeBuild -Global
            Invoke-Build -Task $BuildType -File $buildScript -BuildInfo $instance
        } catch {
            throw
        } finally {
            if ($shouldClean) {
                Remove-Item $buildScript
            }
        }
    }
}