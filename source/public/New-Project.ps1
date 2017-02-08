function New-Project {
    # .SYNOPSIS
    #   Create a new module.
    # .DESCRIPTION
    #   A very basic module creation tool.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     08/02/2017 - Chris Dent - Created.

    [CmdletBinding()]
    param(
        [String]$Name,

        [String]$ProjectName = $Name,

        [String]$Path
    )

    $projectPath = $moduleBase = Join-Path $psmoduleconfig.DevRoot $ProjectName

    if (-not (Test-Path $projectPath)) {
        $null = New-Item $projectPath -ItemType Directory -Force
    }

    if ($Name -ne $ProjectName) {
        $moduleBase = Join-Path $projectPath $Name

        if (-not (Test-Path $moduleBase)) {
            $null = New-Item $moduleBase -ItemType Directory -Force
        }
    }

    $params = @{
        Path              = Join-Path $moduleBase ('{0}.psd1' -f $Name)
        Author            = $psmoduleconfig.Author
        Company           = $psmoduleconfig.Company
        AliasesToExport   = $null
        CmdletsToExport   = $null
        FunctionsToExport = $null
        VariablesToExport = $null
        ModuleVersion     = '0.1'
    }
    if (-not $psmoduleconfig.Company) {
        $params.Company = $psmoduleconfig.Author
    }
    New-ModuleManifest @params

    Copy-Item .git* -Destination $projectPath
    Copy-Item 'LICENSE', 'build.ps1' -Destination $moduleBase
}