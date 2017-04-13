function Start-Build {
    [CmdletBinding()]
    param(
        [BuildType]$BuildType = 'Build, Test',

        [String]$ReleaseType = 'Build'
    )

    try {
        $buildInfo = Get-BuildInfo @psboundparameters

        $progressParams = @{
            Activity = 'Building {0} ({1})' -f $buildInfo.ModuleName, $buildInfo.Version
            Id       = 1
        }
        Write-Progress @progressParams

        Write-Message ('Building {0} ({1})' -f $buildInfo.ModuleName, $buildInfo.Version)
        
        foreach ($task in $buildInfo.BuildTask) {
            $taskInfo = New-Object PSObject
            Invoke-BuildTask $task -BuildInfo $BuildInfo -TaskInfo ([Ref]$taskInfo)

            if ($PassThru) {
                $taskInfo
            }

            if ($taskInfo.Result -ne 'Success') {
                throw $taskInfo.Errors
            }
        }

        Write-Message "Build succeeded!" -ForegroundColor Green

        $lastexitcode = 0
    } catch {
        Write-Message 'Build Failed!' -ForegroundColor Red

        $lastexitcode = 1

        # Catches unexpected errors, rethrows errors raised while executing steps.
        throw
    }
}