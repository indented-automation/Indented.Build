#region:TestFileHeader
param (
    [Boolean]$UseExisting
)

if (-not $UseExisting) {
    $moduleBase = $psscriptroot.Substring(0, $psscriptroot.IndexOf("\test"))
    $stubBase = Resolve-Path (Join-Path $moduleBase "test*\stub\*")
    if ($null -ne $stubBase) {
        $stubBase | Import-Module -Force
    }

    Import-Module $moduleBase -Force
}
#endregion

InModuleScope Indented.Build {
    Describe Update-DevRootModule -Tag CI {
        BeforeAll {
            New-Item TestDrive:\Module\Module\public -ItemType Directory -Force
            Set-Content TestDrive:\Module\Module\public\functions.ps1 -Value @(
                'function Get-Something { }'
                'function Set-Something { }'
            )

            $defaultParams = @{
                BuildInfo = [PSCustomObject]@{
                    ModuleName = 'Module'
                    Path       = [PSCustomObject]@{
                        Source = [PSCustomObject]@{
                            Module = Get-Item (Get-Item 'TestDrive:\Module\Module').FullName
                        }
                    }
                    PSTypeName = 'Indented.BuildInfo'
                }
            }
        }

        It 'Generates a psm1 file' {
            Update-DevRootModule @defaultParams

            'TestDrive:\Module\Module\Module.psm1' | Should -Exist
        }

        It 'Dot-sources any files containing code' {
            Update-DevRootModule @defaultParams

            'TestDrive:\Module\Module\Module.psm1' | Should -FileContentMatchMultiline '\$public = @\([\s\S]+?functions'
        }

        It 'Exports functions from a folder named public' {
            Update-DevRootModule @defaultParams

            'TestDrive:\Module\Module\Module.psm1' | Should -FileContentMatchMultiline '\$functionsToExport = @\([\s\S]+?Get-Something[\s\S]+?Set-Something'
        }
    }
}

