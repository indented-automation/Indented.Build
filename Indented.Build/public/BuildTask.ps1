function BuildTask {
    <#
    .SYNOPSIS
        Create a build task object.
    .DESCRIPTION
        A build task is a predefined task used to build well-structured PowerShell projects.
    #>

    [OutputType('BuildTask')]
    param (
        # The name of the task.
        [Parameter(Mandatory = $true)]
        [String]$Name,

        # The stage during which the task will be invoked.
        [Parameter(Mandatory = $true)]
        [ValidateSet('Setup', 'Build', 'Test', 'Release', 'Publish')]
        [BuildType]$Stage,

        # Properties which define the task. The implementation property is mandatory.
        [Hashtable]$Properties,

        # The task implementation.
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$Implementation
    )

    $buildTask = [PSCustomObject]@{
        Name           = $Name
        Stage          = $Stage
        If             = { $true }
        Order          = 1024
        Implementation = $Implementation
    } | Add-Type -MemberName 'BuildTask' -PassThru

    if ($Properties.Contains('If')) {
        $buildTask.If = $Properties.If
    }
    if ($Properties.Contains('Order')) {
        $buildTask.Order = $Properties.Order
    }

    return $buildTask
}