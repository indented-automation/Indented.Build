function Start-Build {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [BuildType]$BuildType = 'Build, Test',

        [ValidateSet('Build', 'Minor', 'Major')]
        [ReleaseType]$ReleaseType = 'Build',

        [Switch]$PassThru,

        [Switch]$Quiet
    )

    try {
        $null = $psboundparameters.Remove('PassThru')
        $null = $psboundparameters.Remove('Quiet')
        $buildInfo = Get-BuildInfo @psboundparameters

        $progressParams = @{
            Activity = 'Building {0} ({1})' -f $buildInfo.ModuleName, $buildInfo.Version
            Id       = 1
        }
        Write-Progress @progressParams

        Write-Message ('Building {0} ({1})' -f $buildInfo.ModuleName, $buildInfo.Version) -Quiet:$Quiet.ToBool() -WithPadding
        
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

        Write-Message "Build succeeded!" -ForegroundColor Green -Quiet:$Quiet.ToBool() -WithPadding

        $lastexitcode = 0
    } catch {
        Write-Message 'Build Failed!' -ForegroundColor Red -Quiet:$Quiet.ToBool() -WithPadding

        $lastexitcode = 1

        # Catches unexpected errors, rethrows errors raised while executing steps.
        throw
    }
}