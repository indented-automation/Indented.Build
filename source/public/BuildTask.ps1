function BuildTask {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name,

        [Parameter(Mandatory = $true)]
        [BuildType]$Stage,

        [Parameter(Mandatory = $true)]
        [Hashtable]$Properties
    )

    $buildTask = New-Object BuildTask($Name, $Stage)
    $Properties.Keys | ForEach-Object {
        $buildTask.$_ = $Properties.$_
    }

    return $buildTask
}