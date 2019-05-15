function Add-PesterTemplate {
    <#
    .SYNOPSIS
        Add a pester template file for each function or class in the module.
    .DESCRIPTION
        Add a pester template file for each function or class in the module.

        Adds new files only.
    #>

    [CmdletBinding()]
    param (
        # BuildInfo is used to determine the source path.
        [Parameter(ValueFromPipeline)]
        [PSTypeName('Indented.BuildInfo')]
        [PSObject]$BuildInfo = (Get-BuildInfo)
    )

    begin {
        $header = @(
            '#region:TestFileHeader'
            'param ('
            '    [Boolean]$UseExisting'
            ')'
            ''
            'if (-not $UseExisting) {'
            '    $moduleBase = $psscriptroot.Substring(0, $psscriptroot.IndexOf("\test"))'
            '    $stubBase = Resolve-Path (Join-Path $moduleBase "test*\stub\*")'
            '    if ($null -ne $stubBase) {'
            '        $stubBase | Import-Module -Force'
            '    }'
            ''
            '    Import-Module $moduleBase -Force'
            '}'
            '#endregion'
        ) -join ([Environment]::NewLine)
    }

    process {
        $testPath = Join-Path $buildInfo.Path.Source.Module 'test*'
        if (Test-Path $testPath) {
            $testPath = Resolve-Path $testPath
        } else {
            $testPath = (New-Item (Join-Path $buildInfo.Path.Source.Module 'test') -ItemType Directory).FullName
        }

        foreach ($file in $buildInfo | Get-BuildItem -Type ShouldMerge) {
            $relativePath = $file.FullName -replace ([Regex]::Escape($buildInfo.Path.Source.Module)) -replace '^\\' -replace '\.ps1$'
            $fileTestPath = Join-Path $testPath ('{0}.tests.ps1' -f $relativePath)

            $script = [System.Text.StringBuilder]::new()
            if (-not (Test-Path $fileTestPath)) {
                $null = $script.AppendLine($header).
                                AppendLine().
                                AppendFormat('InModuleScope {0} {{', $buildInfo.ModuleName).AppendLine()

                foreach ($function in $file | Get-FunctionInfo) {
                    $null = $script.AppendFormat('    Describe {0} -Tag CI {{', $function.Name).AppendLine().
                                    AppendLine('    }').
                                    AppendLine()
                }

                $null = $script.AppendLine('}')

                $parent = Split-Path $fileTestPath -Parent
                if (-not (Test-Path $parent)) {
                    $null = New-Item $parent -ItemType Directory -Force
                }
                Set-Content -Path $fileTestPath -Value $script.ToString().Trim()
            }
        }
    }
}