InModuleScope Indented.Build {
    Describe GetVersion {
        BeforeAll {
            $path = 'TestDrive:\manifest.psd1'
        }

        Context 'Manifest exists, contains version' {
            BeforeAll {
                New-ModuleManifest -Path $path -ModuleVersion 1.2.3
            }

            It 'Output: Version from manifest' {
                GetVersion $path | Should -Be ([Version]'1.2.3')
            }
        }

        Context 'Manifest exists, no version' {
            BeforeAll {
                New-ModuleManifest -Path $path
            }

            It 'Output: Default version' {
                GetVersion $path | Should -Be ([Version]'1.0.0')
            }
        }

        Context 'Manifest does not exist' {
            It 'Output: Default version' {
                GetVersion $path | Should -Be ([Version]'1.0.0')
            }
        }

        Context 'Manifest is not specified' {
            It 'Output: Default version' {
                GetVersion | Should -Be ([Version]'1.0.0')
            }
        }
    }
}