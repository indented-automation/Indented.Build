function Invoke-Step {
    # .SYNOPSIS
    #   Invoke a build step.
    # .DESCRIPTION
    #   An output display wrapper to show progress through a build.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Object
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     01/02/2017 - Chris Dent - Added help.
    
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Step
    )

    begin {
        $erroractionpreference = 'Stop'

        Push-Location $psscriptroot
    }
    
    process {
        $result = 'Success'
        $messageColour = 'Green'

        Write-Progress -Activity "Building $($buildInfo.ModuleName)" -Status "$(Get-Date -Format 't'): Executing $Step" -Id 0

        $stopWatch = New-Object System.Diagnostics.StopWatch
        $stopWatch.Start()

        try {
            & $Step
        } catch {
            $result = 'Fail'
            $messageColour = 'Red'

            throw
        } finally {
            $stopWatch.Stop()

            Write-Host $step.PadRight(30) -ForegroundColor Cyan -NoNewline
            Write-Host -ForegroundColor $messageColour -Object $result.PadRight(10) -NoNewline
            Write-Host (Get-Date -Format 't').PadRight(10) -ForegroundColor Gray -NoNewLine
            Write-Host $stopWatch.Elapsed -ForegroundColor Gray

            if ($result -eq 'Fail') {
                Write-Host
            }
        }
    }

    end {
        Pop-Location
    }
}