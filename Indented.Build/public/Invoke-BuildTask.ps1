filter Invoke-BuildTask {
    <#
    .SYNOPSIS
        Invoke a build step.
    .DESCRIPTION
        An output display wrapper to show progress through a build.
    .NOTES
        Change log:
            01/02/2017 - Chris Dent - Added help.
    #>

    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        # The task to invoke.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSTypeName('BuildTask')]
        [PSObject]$BuildTask,

        # Task execution context information.
        [Parameter(Mandatory = $true)]
        [PSTypeName('BuildInfo')]
        [PSObject]$BuildInfo,
        
        # A reference to a PSObject which is used to return detailed execution information as an object.
        [Parameter(Mandatory = $true)]
        [Ref]$TaskInfo,

        # Suppress informational messages.
        [Switch]$Quiet
    )

    $progressParams = @{
        Activity = 'Executing {0}' -f $BuildTask.Name
        Id       = 2
        ParentId = 1
    }
    Write-Progress @progressParams

    $TaskInfo.Value = [PSCustomObject]@{
        Name      = $BuildTask.Name
        Result    = 'Success'
        StartTime = (Get-Date)
        TimeTaken = $null
        Errors    = $null
    }
    $messageColour = 'Green'
    
    $stopwatch = New-Object System.Diagnostics.Stopwatch
    $stopwatch.Start()

    try {
        & $BuildTask.Definition
    } catch {
        $TaskInfo.Value.Result = 'Failed'
        $TaskInfo.Value.Errors = $_
        $messageColour = 'Red'
    }

    $stopwatch.Stop()
    $TaskInfo.Value.TimeTaken = $stopwatch.Elapsed

    if (-not $Quiet) {
        Write-Message $BuildTask.Name.PadRight(30) -ForegroundColor Cyan -NoNewline
        Write-Message -ForegroundColor $messageColour -Object $taskInfo.Value.Result.PadRight(10) -NoNewline
        Write-Message $taskInfo.Value.StartTime.ToString('t').PadRight(10) -ForegroundColor Gray -NoNewLine
        Write-Message $taskInfo.Value.TimeTaken -ForegroundColor Gray
    }
}