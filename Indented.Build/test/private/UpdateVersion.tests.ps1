InModuleScope Indented.Build {
    Describe UpdateVersion {
        BeforeAll {
            $Version = [Version]'2.3.4'
        }
        Context 'ReleaseType: Build' {
            It 'Output: Build incremented' {
                UpdateVersion $Version | Should -Be ([Version]'2.3.5')
                UpdateVersion $Version -ReleaseType Build | Should -Be ([Version]'2.3.5')
            }
        }

        Context 'ReleaseType: Minor' {
            It 'Output: Minor incremented, Build reset' {
                UpdateVersion $Version -ReleaseType Minor | Should -Be ([Version]'2.4.0')
            }
        }

        Context 'ReleaseType: Major' {
            It 'Output: Major incremented, Minor reset, Build reset' {
                UpdateVersion $Version -ReleaseType Major | Should -Be ([Version]'3.0.0')
            }
        }
    }
}