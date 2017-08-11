InModuleScope Indented.Build {
    Describe GetSourcePath {
        BeforeAll {
            $projectRoot = New-Item 'TestDrive:\ProjectName' -ItemType Directory -Force
        }

        Context 'Locate by comparing manifest name to child folder name' {
            BeforeAll {
                $null = New-Item 'TestDrive:\ProjectName\ModuleName\ModuleName.psd1' -Force
            }

            It 'Output: ModuleName directory' {
                GetSourcePath $projectRoot | Should -BeLike '*ProjectName\ModuleName'
            }
        }

        Context 'Locate by comparing project name to child folder name' {
            BeforeAll {
                $null = New-Item 'TestDrive:\ProjectName\ProjectName' -ItemType Directory -Force
            }

            It 'Output: ProjectName directory' {
                GetSourcePath $projectRoot | Should -BeLike '*ProjectName\ProjectName'
            }
        }
    }
}