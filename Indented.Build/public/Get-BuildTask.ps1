function Get-BuildTask {
    <#
    .SYNOPSIS
        Get build tasks.
    .DESCRIPTION
        Get the build tasks deemed to be applicable to this build.
        
        If the ListAvailable parameter is supplied, all available tasks will be returned.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ForBuild')]
    [OutputType('BuildTask')]
    param (
        # A build information object used to determine which tasks will apply to the current build.
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ParameterSetName = 'ForBuild')]
        [PSTypeName('BuildInfo')]
        [PSObject]$BuildInfo,

        # Filter tasks by task name.
        [String]$Name = '*',

        # List all available tasks, irrespective of conditions applied to the task.
        [Parameter(Mandatory = $true, ParameterSetName = 'List')]        
        [Switch]$ListAvailable
    )

    begin {
        if (-not $Name.EndsWith('.ps1') -and -not $Name.EndsWith('*')) {
            $Name += '.ps1'
        }
        $path = Join-Path $psscriptroot 'task'

        if (-not $Script:buildTaskCache) {
            $Script:buildTaskCache = @{}
            Get-ChildItem $path -File -Filter *.ps1 -Recurse | ForEach-Object {
                $task = . $_.FullName
                $Script:buildTaskCache.Add($task.Name, $task)
            }
        }
    }

    process {
        if ($buildInfo) {
            Push-Location $buildInfo.Path.Source
        }

        try {
            $Script:buildTaskCache.Values | Where-Object {
                Write-Verbose ('Evaluating {0}' -f $_.Name)

                $_.Name -like $Name -and ($ListAvailable -or (& $_.If))
            }
        } catch {
            Write-Error -Message ('Failed to evaluate task condition: {0}' -f $_.Exception.Message) -ErrorId 'ConditionEvaluationFailed'
        }

        if ($buildInfo) {
            Pop-Location
        }
    }
}