InModuleScope Indented.Build {
    Describe Get-BuildItem {
    #     BeforeAll {
    #         $toMerge = @(
    #             New-Item 'TestDrive:\enumeration\enum1.ps1' -Force -Value 'enum enum1 { }'
    #             New-Item 'TestDrive:\private\priv1.ps1' -Force -Value 'function priv1 { }'
    #             New-Item 'TestDrive:\public\pub1.ps1' -Force -Value 'function pub1 { }'
    #             New-Item 'TestDrive:\public\nested\pub2.ps1' -Force -Value 'function pub2 { }'
    #             New-Item 'TestDrive:\public\empty1.ps1' -Force
    #             New-Item 'TestDrive:\InitializeModule.ps1' -Force -Value 'function InitializeModule { }'
    #         )
    #         $toCopy = @(
    #             New-Item 'TestDrive:\ModuleName.format.ps1xml' -Force
    #             New-Item 'TestDrive:\other\name.txt' -Force
    #         )
    #         $toIgnore = @(
    #             New-Item 'TestDrive:\class\class1.cs' -Force
    #             New-Item 'TestDrive:\test\test1.tests.ps1' -Force
    #             New-Item 'TestDrive:\help\pub1.md' -Force
    #         )

    #         Push-Location (Get-Item 'TestDrive:\').FullName
    #     }
        
    #     AfterAll {
    #         Pop-Location
    #     }

    #     Context 'ShouldMerge' {
    #         It 'Merge: Gets all files which can merge: If file length is greater than 0' {
    #             $items = Get-BuildItem -Type ShouldMerge
    #             $items.Count | Should -Be ($toMerge.Count - 1)
    #         }
    #     }

    #     Context 'Static' {
    #         It 'Static: Gets all static files and folders' {
    #             $items = Get-BuildItem -Type Static
    #             $items.Count | Should -Be $toCopy.Count
    #             $items[0].Name | Should -Be 'other'
    #             $items[1].Name | Should -Be 'ModuleName.format.ps1xml'
    #         }
    #     }
    }
}