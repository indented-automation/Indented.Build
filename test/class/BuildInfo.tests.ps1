InModuleScope Indented.Build {
    Describe BuildInfo {
        Mock git
        Mock Get-BuildTask
        Mock Get-Metadata

        Context 'Constructors' {
            
        }

        Context 'GetBuildTask' {

        }

        Context 'GetModuleName' {
            BeforeEach {
                $instance = New-Object BuildInfo
                $item = New-Item TestDrive:\ModuleName\source -ItemType Directory -Force
                $testDrive = (Get-Item TestDrive:).FullName
            }

            It 'Gets a module name from a source path' {
                $instance.Source = Join-Path $testDrive 'ModuleName\source'
                $instance.GetModuleName() | Should -Be 'ModuleName'
            }

            It 'Fixes incorrect casing in a module name when source is contained in a "source" directory' {
                $instance.Source = Join-Path $testDrive 'modulename\source'
                $instance.GetModuleName() | Should -BeExactly 'ModuleName'
            }

            It 'Fixes incorrect casing in a module name without a "source" directory' {
                $instance.Source = Join-Path $testDrive 'modulename'
                $instance.GetModuleName() | Should -BeExactly 'ModuleName'
            }
        }

        Context 'GetSourcePath' {
            BeforeEach {
                $instance = New-Object BuildInfo
                if (Test-Path TestDrive:\ProjectRoot) {
                    Remove-Item TestDrive:\ProjectRoot -Recurse
                }
                $instance.ProjectRoot = (New-Item 'TestDrive:\ProjectRoot' -ItemType Directory).FullName
            }

            It 'Returns ProjectRoot\source when the project root contains a "source" directory' { 
                $null = New-Item (Join-Path $instance.ProjectRoot 'source') -ItemType Directory -Force
                $instance.GetSourcePath() | Should -BeLike '*\ProjectRoot\source'
            }

            It 'Returns pwd\source when PWD contains a "source" directory' {
                $null = New-Item (Join-Path $instance.ProjectRoot 'ModuleName\source') -ItemType Directory -Force

                Push-Location 'TestDrive:\ProjectRoot\ModuleName'

                $instance.GetSourcePath() | Should -BeLike '*\ProjectRoot\ModuleName\source'

                Pop-Location
            }

            It 'Returns pwd when PWD is named "source"' {
                $null = New-Item (Join-Path $instance.ProjectRoot 'ModuleName\source') -ItemType Directory -Force

                Push-Location 'TestDrive:\ProjectRoot\ModuleName\source'

                $instance.GetSourcePath() | Should -BeLike '*\ProjectRoot\ModuleName\source'

                Pop-Location
                
            }

            It 'Returns pwd when pwd contains a .psd1 file named after the parent directory' {
                $null = New-Item (Join-Path $instance.ProjectRoot 'ModuleName') -ItemType Directory -Force
                $null = New-Item (Join-Path $instance.ProjectRoot 'ModuleName\ModuleName.psd1') -ItemType File -Force

                Push-Location 'TestDrive:\ProjectRoot\ModuleName'

                $instance.GetSourcePath() | Should -BeLike '*\ProjectRoot\ModuleName'

                Pop-Location
            }

            It 'Returns ProjectRoot\(ProjectRoot.Name) when the ProjectRoot contains a directory with the same name' {
                $null = New-Item (Join-Path $instance.ProjectRoot 'ProjectRoot') -ItemType Directory -Force

                Push-Location 'TestDrive:\ProjectRoot'

                $instance.GetSourcePath() | Should -BeLike '*\ProjectRoot\ProjectRoot'

                Pop-Location
            }
        }

        Context 'GetVersion' {

        }

        Context 'IncrementVersion' {

        }
    }
}