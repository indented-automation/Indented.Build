InModuleScope Indented.Build {
    Describe Get-BuildInfo {
        BeforeAll {
            Mock GetBranchName { 'master' }
            Mock GetBuildSystem { 'Unknown' }
            Mock GetLastCommitMessage { 'Commit message' }
            Mock GetProjectRoot { Get-Item 'TestDrive:\ModuleName' }
            Mock GetSourcePath { Get-Item 'TestDrive:\ModuleName\ModuleName' }
            Mock GetVersion { [Version]'1.0.0' }
            Mock UpdateVersion { [Version]'1.0.0' }

            New-Item 'TestDrive:\ModuleName\ModuleName\ModuleName.psd1' -ItemType File -Force
            New-Item 'TestDrive:\ProjectName\ModuleName\ModuleName.psd1' -ItemType File -Force
        }

        Context 'Normal operation' {
            BeforeAll {
                $buildInfo = Get-BuildInfo
            }

            It 'Object: TypeName: Is BuildInfo' {
                $buildInfo.PSObject.TypeNames -contains 'BuildInfo' | Should -Be $true
            }

            It 'Command: Calls GetBuildSystem' {
                Assert-MockCalled GetBuildSystem
            }

            It 'Command: Calls GetBranchName' {
                Assert-MockCalled GetBranchName
            }

            It 'Command: Calls GetLastCommitMessage' {
                Assert-MockCalled GetLastCommitMessage
            }

            It 'Command: Calls GetProjectRoot' {
                Assert-MockCalled GetProjectRoot
            }

            It 'Command: Calls GetSourcePath' {
                Assert-MockCalled GetSourcePath
            }

            It 'Command: Calls GetVersion' {
                Assert-MockCalled GetVersion
            }

            It 'Command: Calls UpdateVersion' {
                Assert-MockCalled UpdateVersion
            }
        }

        Context 'ReleaseType switching' {
            It 'ReleaseType: Major: When the commit message includes major release' {
                Mock GetLastCommitMessage { 'major release' }

                (Get-BuildInfo).ReleaseType | Should -Be 'Major'
            }

            It 'ReleaseType: Minor: When commit message includes release' {
                Mock GetLastCommitMessage { 'release' }

                (Get-BuildInfo).ReleaseType | Should -Be 'Minor'
            }

            It 'ReleaseType: Build: By default' {
                Mock GetLastCommitMessage { 'Commit message' }

                (Get-BuildInfo).ReleaseType | Should -Be 'Build'
            }

            It 'ReleaseType: By argument: When argument is supplied' {
                Mock GetLastCommitMessage { 'major release' }

                (Get-BuildInfo -ReleaseType 'Build').ReleaseType | Should -Be 'Build'
                (Get-BuildInfo -ReleaseType 'Minor').ReleaseType | Should -Be 'Minor'

                Mock GetLastCommitMessage { 'release' }

                (Get-BuildInfo -ReleaseType 'Major').ReleaseType | Should -Be 'Major'
            }
        }

        Context 'Paths affected by project root' {
            It 'Path.Package: Is "ProjectRoot\Version": When the ProjectRoot name and the ModuleName are equal' {
                Mock GetProjectRoot { 
                    Get-Item 'TestDrive:\ModuleName'
                }
 
                (Get-BuildInfo).Path.Package | Should -BeLike '*\ModuleName\1.0.0'
            }

            It 'Path.Package: Is "ProjectRoot\build\ModuleName\Version": When the ProjectRoot name and the ModuleName differ' {
                Mock GetProjectRoot { 
                    Get-Item 'TestDrive:\ProjectName'
                }

                (Get-BuildInfo).Path.Package | Should -BeLike '*\ProjectName\build\ModuleName\1.0.0'
            }

            It 'Path.Output: Is "ProjectRoot\Output": When the ProjectRoot name and the ModuleName are equal' {
                Mock GetProjectRoot { 
                    Get-Item 'TestDrive:\ModuleName'
                }

                (Get-BuildInfo).Path.Output | Should -BeLike '*\ModuleName\output'
            }

            It 'Path.Output: Is "ProjectRoot\build\output\ModuleName": When the ProjectRoot name and the ModuleName differ' {
                Mock GetProjectRoot { 
                    Get-Item 'TestDrive:\ProjectName'
                }

                (Get-BuildInfo).Path.Output | Should -BeLike '*\ProjectName\build\output\ModuleName'
            }
        }
    }
}