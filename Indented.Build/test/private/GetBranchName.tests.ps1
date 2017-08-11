InModuleScope Indented.Build {
    Describe GetBranchName {
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

        It 'Output: master when master is checked out' {
            GetBranchName | Should -Be 'master'
        }

        It 'Output: branchname when branchname is checked out' {
            git checkout -b 'branchname' *> $null
            GetBranchName | Should -Be 'branchname'
        }
    }
}