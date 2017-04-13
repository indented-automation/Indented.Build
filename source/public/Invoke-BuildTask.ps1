using namespace System.Diagnostics

function Invoke-BuildTask {
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
        [BuildTask]$BuildTask,

        [BuildInfo]$BuildInfo,
        
        [Ref]$TaskInfo
    )

    begin {
        $stopWatch = New-Object StopWatch
    }
    
    process {
        $progressParams = @{
            Activity = 'Executing {0}' -f $BuildTask.Name
            Id       = 2
            ParentId = 1
        }
        Write-Progress @progressParams

        $TaskInfo.Value = [PSCustomObject]@{
            Name      = $BuildTask.Name
            Result    = 'Success'
            StartTime = [DateTime]::Now
            TimeTaken = $null
            Errors    = $null
        }
        $messageColour = 'Green'
        
        $stopWatch = New-Object System.Diagnostics.StopWatch
        $stopWatch.Start()

        try {
            $BuildTask.Implementation.InvokeWithContext($null, (Get-Variable buildInfo), $null)
        } catch {
            $TaskInfo.Value.Result = 'Failed'
            $TaskInfo.Value.Errors = $_.Exception.InnerException
            $messageColour = 'Red'
        }

        $stopWatch.Stop()
        $TaskInfo.Value.TimeTaken = $stopWatch.Elapsed

        if (-not $Quiet) {
            Write-Host $BuildTask.Name.PadRight(30) -ForegroundColor Cyan -NoNewline
            Write-Host -ForegroundColor $messageColour -Object $taskInfo.Value.Result.PadRight(10) -NoNewline
            Write-Host $taskInfo.Value.StartTime.ToString('t').PadRight(10) -ForegroundColor Gray -NoNewLine
            Write-Host $taskInfo.Value.TimeTaken -ForegroundColor Gray
        }
    }
}