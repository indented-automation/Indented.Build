InModuleScope Indented.Build {
    Describe Get-BuildInfo {
        BeforeAll {
            Mock GetBuildSystem { 'Desktop' }

            New-Item 'TestDrive:\ProjectName\ModuleName' -ItemType Directory
            New-ModuleManifest 'TestDrive:\ProjectName\ModuleName\ModuleName.psd1' -RootModule ModuleName.psm1 -ModuleVersion 1.0.0

            $defaultParams = @{
                ProjectRoot = 'TestDrive:\ProjectName'
            }
        }

        Context 'Normal operation' {
            BeforeAll {
                $buildInfo = Get-BuildInfo @defaultParams
            }

            It 'Object: TypeName: Is BuildInfo' {
                $buildInfo | Should -Not -BeNullOrEmpty
                $buildInfo.PSTypeNames | Should -Contain 'Indented.BuildInfo'
            }

            It 'Command: Calls GetBuildSystem' {
                Assert-MockCalled GetBuildSystem
            }
        }

        Context 'Paths generation' {
            It 'Path.Build.Module usese the convention "ProjectRoot\build\ModuleName\Version"' {
                (Get-BuildInfo @defaultParams).Path.Build.Module | Should -BeLike '*\ProjectName\build\ModuleName\1.0.0'
            }

            It 'Path.Build.Output usese the convention "ProjectRoot\build\output": ' {
                (Get-BuildInfo @defaultParams).Path.Build.Output | Should -BeLike '*\ProjectName\build\output\ModuleName'
            }
        }
    }
}