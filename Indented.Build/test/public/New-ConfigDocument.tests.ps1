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
    Describe New-ConfigDocument -Tag CI {
        BeforeAll {
            New-Item TestDrive:\Module\Module -ItemType Directory -Force

            $defaultParams = @{
                BuildInfo = [PSCustomObject]@{
                    ModuleName = 'Module'
                    Path       = [PSCustomObject]@{
                        ProjectRoot = Get-Item 'TestDrive:\Module'
                        Source = [PSCustomObject]@{
                            Module = Get-Item 'TestDrive:\Module\Module'
                        }
                    }
                    PSTypeName = 'Indented.BuildInfo'
                }
            }
        }

        It 'Creates a build configuration file' {
            New-ConfigDocument @defaultParams

            'TestDrive:\Module\Module\buildConfig.psd1' | Should -Exist
        }
    }
}

