filter Start-Build {
    <#
    .SYNOPSIS
        Start a build.
    .DESCRIPTION
        Start a build using the built-in task executor.
    #>

    [CmdletBinding()]
    [OutputType('TaskInfo')]
    param (
        # The task categories to execute.
        [String[]]$BuildType = @('Setup', 'Build', 'Test'),

        # The release type to create.
        [ValidateSet('Build', 'Minor', 'Major')]
        [String]$ReleaseType = 'Build',

        [Parameter(ValueFromPipeline = $true)]
        [PSTypeName('BuildInfo')]
        [PSObject]$BuildInfo = (Get-BuildInfo -BuildType $BuildType -ReleaseType $ReleaseType)
    )

    $buildScript = Join-Path $buildInfo.Path.Source '.build.ps1'
    $shouldClean = $false
    if (-not (Test-Path $buildScript)) {
        $BuildInfo | Export-BuildScript | Out-File $buildScript
        $shouldClean = $true
    }

    Invoke-Build -Task $BuildType -File $buildScript

    if ($shouldClean) {
        Remove-Item $buildScript
    }
}