function Start-Build {
    try {
        Push-Location $psscriptroot

        # Expand steps
        $Steps = $Steps | ForEach-Object { & $_ }
        $buildInfo = New-Object BuildInfo($Steps, $ReleaseType)
        if ($GetBuildInfo) {
            return $buildInfo
        } else {
            $Script:Quiet = $Quiet.ToBool()

            Write-Message ('Building {0} ({1})' -f $buildInfo.ModuleName, $buildInfo.Version)
            
            foreach ($step in $steps) {
                $stepInfo = Invoke-Step $step

                if ($PassThru) {
                    $stepInfo
                }

                if ($stepInfo.Result -ne 'Success') {
                    throw $stepinfo.Errors
                }
            }

            Write-Message "Build succeeded!" -ForegroundColor Green

            $lastexitcode = 0
        }
    } catch {
        Write-Message 'Build Failed!' -ForegroundColor Red

        $lastexitcode = 1

        # Catches unexpected errors, rethrows errors raised while executing steps.
        throw
    } finally {
        Pop-Location
    }
}