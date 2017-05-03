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
        [BuildType]$BuildType = 'Setup, Build, Test',

        # The release type to create.
        [ReleaseType]$ReleaseType = 'Build',

        [Parameter(ValueFromPipeline = $true)]
        [PSTypeName('BuildInfo')]
        [PSObject]$BuildInfo = (Get-BuildInfo -BuildType $BuildType -ReleaseType $ReleaseType),

        # Return task information as an object.
        [Switch]$PassThru,

        # Suppress informational output.
        [Switch]$Quiet
    )

    try {
        $progressParams = @{
            Activity = 'Building {0} ({1})' -f $BuildInfo.ModuleName, $BuildInfo.Version
            Id       = 1
        }
        Write-Progress @progressParams

        Write-Message ('Building {0} ({1})' -f $BuildInfo.ModuleName, $BuildInfo.Version) -Quiet:$Quiet.ToBool() -WithPadding
        
        $BuildInfo | Get-BuildTask | ForEach-Object {
            $taskInfo = New-Object PSObject
            
            $_ | Invoke-BuildTask -BuildInfo $BuildInfo -TaskInfo ([Ref]$taskInfo)

            if ($PassThru) {
                $taskInfo
            }

            if ($taskInfo.Result -ne 'Success') {
                throw $taskInfo.Errors
            }
        }

        Write-Message "Build succeeded!" -ForegroundColor Green -Quiet:$Quiet.ToBool() -WithPadding

        $lastexitcode = 0
    } catch {
        Write-Message 'Build Failed!' -ForegroundColor Red -Quiet:$Quiet.ToBool() -WithPadding

        $lastexitcode = 1

        # Catches unexpected errors, rethrows errors raised while executing steps.
        Write-Error -ErrorRecord $_
    }
}