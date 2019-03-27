function Update-DevRootModule {
    <#
    .SYNOPSIS
        Update a dev root module which dot-sources all module content.
    .DESCRIPTION
        Create or update a root module file which loads module content using dot-sourcing.

        All content which should would normally be merged is added to a psm1 file. All other module content, such as required assebmlies, is ignored.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        # BuildInfo is used to determine the source path.
        [Parameter(ValueFromPipeline)]
        [PSTypeName('Indented.BuildInfo')]
        [PSObject]$BuildInfo = (Get-BuildInfo)
    )

    process {
        $script = [System.Text.StringBuilder]::new()

        $groupedItems = $buildInfo |
            Get-BuildItem -Type ShouldMerge |
            Where-Object BaseName -ne 'InitializeModule' |
            Group-Object BuildItemType

        $null = foreach ($group in $groupedItems) {
            $script.AppendFormat('${0} = @(', $group.Name).AppendLine()
            foreach ($file in $group.Group) {
                $relativePath = $file.FullName -replace ([Regex]::Escape($buildInfo.Path.Source.Module)) -replace '^\\' -replace '\.ps1$'
                $groupTypePath, $relativePath = $relativePath -split '\\', 2

                $script.AppendFormat("    '{0}'", $relativePath).AppendLine()
            }
            $script.AppendLine(')').AppendLine()

            $script.AppendFormat('foreach ($file in ${0}) {{', $group.Name).AppendLine().
                    AppendFormat('    . ("{{0}}\{0}\{{1}}.ps1" -f $psscriptroot, $file)', $groupTypePath).AppendLine().
                    AppendLine('}').
                    AppendLine()


            if ($group.Name -eq 'public') {
                $script.AppendLine('$functionsToExport = @(')

                foreach ($function in $group.Group | Get-FunctionInfo) {
                    $script.AppendFormat("    '{0}'", $function.Name).AppendLine()
                }

                $script.AppendLine(')')
                $script.AppendLine('Export-ModuleMember -Function $functionsToExport').AppendLine()
            }
        }

        $initializeScriptPath = Join-Path $buildInfo.Path.Source.Module.FullName 'InitializeModule.ps1'
        if (Test-Path $initializeScriptPath) {
            $null = $script.AppendLine('. ("{0}\InitializeModule.ps1" -f $psscriptroot)').
                            AppendLine('InitializeModule')
        }

        $rootModulePath = Join-Path $buildInfo.Path.Source.Module ('{0}.psm1' -f $buildInfo.ModuleName)
        Set-Content -Path $rootModulePath -Value $script.ToString()
    }
}