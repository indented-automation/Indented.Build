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
    Describe Add-PesterTemplate -Tag CI {
        BeforeAll {
            Mock Get-BuildItem {
                Get-Item TestDrive:\Module\Module\public\function.ps1
            }
            Mock Get-FunctionInfo {
                [PSCustomObject]@{
                    Name = 'functionName'
                }
            }

            New-Item TestDrive:\Module\Module\public\function.ps1 -Force

            $defaultParams = @{
                BuildInfo = [PSCustomObject]@{
                    ModuleName = 'Module'
                    Path       = [PSCustomObject]@{
                        Source = [PSCustomObject]@{
                            Module = Join-Path $TestDrive 'Module\Module'
                        }
                    }
                    PSTypeName = 'Indented.BuildInfo'
                }
            }
        }

        It 'Generates missing .tests.ps1 files' {
            Add-PesterTemplate @defaultParams

            'TestDrive:\Module\Module\test\public\function.tests.ps1' | Should -Exist
        }

        It 'Writes a header to generated files' {
            'TestDrive:\Module\Module\test\public\function.tests.ps1' | Should -FileContentMatch 'region:TestFileHeader'
        }

    }
}