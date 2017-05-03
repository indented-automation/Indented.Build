InModuleScope Indented.Build {
    Describe Get-FunctionInfo {
        It 'Object: Create FunctionInfo: From ScriptBlock' {
            $scriptBlock = {
                function Get-Something { }
            }

            $functionInfo = Get-FunctionInfo -ScriptBlock $scriptBlock
            $functionInfo.Name | Should -Be 'Get-Something'
        }

        It 'Object: Create FunctionInfo: From file' {
            'function Get-Something { }' | Out-File TestDrive:\script.ps1

            $functionInfo = Get-FunctionInfo -Path TestDrive:\script.ps1
            $functionInfo.Name | Should -Be 'Get-Something'
        }

        It 'Object: Finds nested functions: When IncludeNested is set' {
            $scriptBlock = {
                function Get-Something {
                    function Find-Something { }
                }
            }

            $functionInfo = Get-FunctionInfo -ScriptBlock $scriptBlock
            @($functionInfo).Count | Should -Be 1

            $functionInfo = Get-FunctionInfo -ScriptBlock $scriptBlock -IncludeNested
            @($functionInfo).Count | Should -Be 2
        }

        It 'Error: Non-Terminating (InvalidScriptBlock): When a script contains an error' {
            'function Get-Something {' | Out-File TestDrive:\script.ps1

            { Get-FunctionInfo -Path TestDrive:\script.ps1 -ErrorAction Stop } | Should -Throw -ErrorID 'InvalidScriptBlock'
        }
    }
}