InModuleScope Indented.Build {
    Describe BuildTask {
        It 'Object: TypeName: Is BuildTask' {
            $buildTask = BuildTask -Name 'name' -Stage 'Build' -Definition { }
            $buildTask.PSObject.TypeNames -contains 'BuildTask' | Should -Be $true
        }

        It 'Object: Has default values: When using mandatory parameters only' {
            $buildTask = BuildTask -Name 'name' -Stage 'Build' -Definition { }
            $buildTask.Order | Should -Be 1024
            & $buildTask.If | Should -Be $true
        }

        It 'Object: Accepts values from parameters: When parameter arguments are given' {
            $buildTask = BuildTask -Name 'name' -Stage 'Build' -Order 0 -If { $false } -Definition { }
            $buildTask.Order | Should -Be 0
            & $buildTask.If | Should -Be $false
        }
    }
}