InModuleScope Indented.Build {
    Describe GetModuleName {
        BeforeAll {
            New-Item 'TestDrive:\ProjectName\ModuleName\source' -ItemType Directory -Force
            New-Item 'TestDrive:\ProjectName\ModuleName\src' -ItemType Directory -Force
        }

        It 'Output: Returns the name of the module' {
            GetModuleName (Get-Item 'TestDrive:\ProjectName\ModuleName') | Should -Be 'ModuleName'
        }

        It 'Output: Returns the name of the module: When the path contains "source" or "src"' {
            GetModuleName (Get-Item 'TestDrive:\ProjectName\ModuleName\source') | Should -Be 'ModuleName'
            GetModuleName (Get-Item 'TestDrive:\ProjectName\ModuleName\src') | Should -Be 'ModuleName'
        }

        It 'Output: Returns the name of the module with correct case' {
            GetModuleName (Get-Item 'TestDrive:\projectname\modulename') | Should -BeExactly 'ModuleName'
        }
    }
}