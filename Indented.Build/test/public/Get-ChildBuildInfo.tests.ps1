InModuleScope Indented.Build {
    Describe Get-ChildBuildInfo {
        BeforeAll {
            $validModules = @(
                New-Item 'TestDrive:\ProjectName\module1\module1.psd1' -Force -Value '@{}'
                New-Item 'TestDrive:\ProjectName\module2\module2.psd1' -Force -Value '@{}'
            )
            $invalidFiles = @(
                New-Item 'TestDrive:\ProjectName\otherfolder\file.psd1' -Force -Value '@{}'
            )

            Mock Get-BuildInfo { $Path }
            Mock Write-Debug

            Push-Location (Get-Item TestDrive:\)
        }

        AfterAll {
            Pop-Location
        }

        It 'BuildInfo: Gets all valid modules: Where a manifest exists, and the file name matches the parent folder' {
            $items = Get-ChildBuildInfo
            @($items).Count | Should -Be 2
        }

        It 'Debug: Writes a debug message: When an exception is thrown by Get-BuildInfo' {
            Mock Get-BuildInfo { throw }

            Get-ChildBuildInfo

            Assert-MockCalled Write-Debug
        }
    }
}