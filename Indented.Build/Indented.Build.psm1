# Development root module

$private = @(
    'GetBuildSystem'
)

foreach ($command in $private) {
    . ('{0}\private\{1}.ps1' -f $psscriptroot, $command)

    Split-Path $command -Leaf
}

$public = @(
    'BuildTask'
    'ConvertTo-ChocoPackage'
    'Enable-Metadata'
    'Export-BuildScript'
    'Get-BuildInfo'
    'Get-BuildItem'
    'Get-BuildTask'
    'Get-FunctionInfo'
    'Start-Build'
)

$functionsToExport = foreach ($command in $public) {
    . ('{0}\public\{1}.ps1' -f $psscriptroot, $command)

    Split-Path $command -Leaf
}

. ('{0}\InitializeModule.ps1' -f $psscriptroot)
InitializeModule

Export-ModuleMember -Function $functionsToExport