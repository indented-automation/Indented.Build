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
    Describe Start-Build -Tag CI {
        BeforeAll {
            Mock Export-BuildScript {
                Set-Content TestDrive:\Module\.build.ps1 -Value @(
                    'param ( $BuildInfo )'
                    'Task default { }'
                )
            }

            New-Item TestDrive:\Module\Module -ItemType Directory -Force

            $defaultParams = @{
                BuildType = 'default'
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

        It 'Generates a build script to use' {
            Start-Build @defaultParams

            Assert-MockCalled Export-BuildScript
        }

        It 'Removes the generated build script' {
            Start-Build @defaultParams

            'TestDrive:\Module\.build.ps1' | Should -Not -Exist
        }
    }
}

