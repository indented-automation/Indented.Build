InModuleScope Indented.Build {
    Describe GetProjectRoot {
        BeforeAll {
            $projectRoot = New-Item TestDrive:\ProjectName -ItemType Directory
            Push-Location $projectRoot.FullName
            git init
            '.tmp' | Out-File '.gitignore' -Encoding UTF8
            git add *
            git commit -m 'initial'
            $null = New-Item .\ModuleName -ItemType Directory
            Push-Location .\ModuleName
        }

        AfterAll {
            Pop-Location
            Pop-Location
        }

        It 'Output: Project directory' {
            GetProjectRoot | Should -Be $projectRoot.FullName
        }
    }
}