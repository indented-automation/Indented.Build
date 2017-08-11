InModuleScope Indented.Build {
    Describe GetLastCommitMessage {
        BeforeAll {
            $projectRoot = New-Item TestDrive:\ProjectName -ItemType Directory
            Push-Location $projectRoot.FullName
            git init
            '.tmp' | Out-File '.gitignore' -Encoding UTF8
            git add *
            git commit -m 'initial'
        }

        AfterAll {
            Pop-Location
        }

        It 'Output: Last commit message' {
            GetLastCommitMessage | Should -Be 'initial'
        }
    }
}