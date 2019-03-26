InModuleScope Indented.Build {
    Describe GetBuildSystem {
        BeforeAll {
            $names = 'APPVEYOR', 'JENKINS_URL'

            # Capture current values
            $valueSet = @{}
            foreach ($name in $names) {
                if (Test-Path env:$name) {
                    $valueSet.$name = (Get-Item env:$name).Value
                }
            }
        }

        AfterAll {
            # Reset all values to the original
            foreach ($name in $names) {
                if ($valueSet.Contains($name)) {
                    Set-Item env:$name -Value $valueSet.$name
                }
            }
        }

        BeforeEach {
            # Clear all values
            foreach ($name in $names) {
                if (Test-Path env:$name) {
                    Remove-Item env:$name
                }
            }
        }

        AfterEach {
            # Clear all values
            foreach ($name in $names) {
                if (Test-Path env:$name) {
                    Remove-Item env:$name
                }
            }
        }

        It 'Output: Default returns "Desktop"' {
            GetBuildSystem | Should -Be 'Desktop'
        }

        It 'Output: Returns AppVeyor: When %APPVEYOR% is true' {
            $env:APPVEYOR = $true

            GetBuildSystem | Should -Be 'AppVeyor'
        }

        It 'Output: Returns Jenkins: When %JENKINS_URL% is set' {
            $env:JENKINS_URL = 'http://jenkins'

            GetBuildSystem | Should -Be 'Jenkins'
        }
    }
}