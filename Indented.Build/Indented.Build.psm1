$private = @(
    'GetBuildSystem'
)

foreach ($file in $private) {
    . ("{0}\private\{1}.ps1" -f $psscriptroot, $file)
}

$public = @(
    'Add-PesterTemplate'
    'BuildTask'
    'Convert-CodeCoverage'
    'ConvertTo-ChocoPackage'
    'Enable-Metadata'
    'Export-BuildScript'
    'Get-Ast'
    'Get-BuildInfo'
    'Get-BuildItem'
    'Get-BuildTask'
    'Get-ClassInfo'
    'Get-FunctionInfo'
    'Get-LevenshteinDistance'
    'Get-MethodInfo'
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
    'Convert-CodeCoverage'
    'ConvertTo-ChocoPackage'
    'Enable-Metadata'
    'Export-BuildScript'
    'Get-Ast'
    'Get-BuildInfo'
    'Get-BuildItem'
    'Get-BuildTask'
    'Get-ClassInfo'
    'Get-FunctionInfo'
    'Get-LevenshteinDistance'
    'Get-MethodInfo'
    'New-ConfigDocument'
    'Start-Build'
    'Update-DevRootModule'
)
Export-ModuleMember -Function $functionsToExport

. ("{0}\InitializeModule.ps1" -f $psscriptroot)
InitializeModule

