InModuleScope Indented.Build {
    Describe TestAdministrator {
        BeforeAll {
            $isAdministrator = [Boolean](-not ((net session *>&1) -match 'Access is denied.'))
        }

        It 'Output: Boolean representing administrative token state' {
            TestAdministrator | Should -Be $isAdministrator
        }
    }
}