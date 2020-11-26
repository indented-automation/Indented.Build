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
