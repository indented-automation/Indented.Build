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
    #   Change log:
    #     01/02/2017 - Chris Dent - Added help.
    
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
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
            & $BuildTask.Implementation
        } catch {
            $TaskInfo.Value.Result = 'Failed'
            $TaskInfo.Value.Errors = $_.Exception.InnerException
            $messageColour = 'Red'
        }

        $stopWatch.Stop()
        $TaskInfo.Value.TimeTaken = $stopWatch.Elapsed

        if (-not $Quiet) {
            Write-Message $BuildTask.Name.PadRight(30) -ForegroundColor Cyan -NoNewline
            Write-Message -ForegroundColor $messageColour -Object $taskInfo.Value.Result.PadRight(10) -NoNewline
            Write-Message $taskInfo.Value.StartTime.ToString('t').PadRight(10) -ForegroundColor Gray -NoNewLine
            Write-Message $taskInfo.Value.TimeTaken -ForegroundColor Gray
        }
    }
}