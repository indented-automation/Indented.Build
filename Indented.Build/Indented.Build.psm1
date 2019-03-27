$private = @(
    'GetBuildSystem'
)

foreach ($file in $private) {
    . ("{0}\private\{1}.ps1" -f $psscriptroot, $file)
}

$public = @(
    'Add-PesterTemplate'
    'BuildTask'
    'ConvertTo-ChocoPackage'
    'Enable-Metadata'
    'Export-BuildScript'
    'Get-BuildInfo'
    'Get-BuildItem'
    'Get-BuildTask'
    'Get-FunctionInfo'
    'New-ConfigDocument'
    'Start-Build'
    'Update-DevRootModule'
)

foreach ($file in $public) {
    . ("{0}\public\{1}.ps1" -f $psscriptroot, $file)
}

$functionsToExport = @(
    'Add-PesterTemplate'
    'BuildTask'
    'ConvertTo-ChocoPackage'
    'Enable-Metadata'
    'Export-BuildScript'
    'Get-BuildInfo'
    'Get-BuildItem'
    'Get-BuildTask'
    'Get-FunctionInfo'
    'New-ConfigDocument'
    'Start-Build'
    'Update-DevRootModule'
)
Export-ModuleMember -Function $functionsToExport

. ("{0}\InitializeModule.ps1" -f $psscriptroot)
InitializeModule

