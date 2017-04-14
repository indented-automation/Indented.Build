InModuleScope Indented.Build {
    Describe BuildTask {
        Mock New-Object { 
            @{}
        }

        Context 'Default' {
            BeforeEach {
                $task = BuildTask -Name 'SomeTask' -Stage 'Build' -Properties @{
                    Order          = 0
                    Implementation = { }
                }
            }

            It 'Creates new instances of BuildTask' {
                Assert-MockCalled New-Object -Times 1 -Scope It
                $task | Should -Not -BeNullOrEmpty
            }

            It 'Adds properties to the build task' {
                $task.Order | Should -Be 0
                $task.Implementation | Should -BeOfType [ScriptBlock]
            }
        }
    }
}