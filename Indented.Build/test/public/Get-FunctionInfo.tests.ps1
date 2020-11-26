Describe Get-FunctionInfo -Tag CI {
    BeforeAll {
        Set-Content 'TestDrive:\script.ps1' -Value @(
            'function FunctionA { }'
            'function FunctionB {'
            ''
            '}'
        )

        $defaultParams = @{
            Path = 'TestDrive:\script.ps1'
        }
    }

    It 'Reads FunctionAst from a file and generates FunctionInfo objects' {
        $functionInfo = Get-FunctionInfo @defaultParams

        $functionInfo.Name | Should -Be 'FunctionA', 'FunctionB'
    }

    It 'Adds position and file information to the functionInfo object' {
        $functionInfo = Get-FunctionInfo @defaultParams

        $functionInfo[0].Extent.File | Should -Be (Get-Item 'TestDrive:\script.ps1').FullName
        $functionInfo[0].Extent.StartLineNumber | Should -Be 1
        $functionInfo[1].Extent.StartLineNumber | Should -Be 2
        $functionInfo[1].Extent.EndLineNumber | Should -Be 4
    }

    It 'Parses functions from a script block' {
        $functionInfo = Get-FunctionInfo -ScriptBlock { function functionC { } }

        $functionInfo.Name | Should -Be 'FunctionC'
    }

    It 'Writes an error if the path is invalid' {
        { Get-FunctionInfo -Path TestDrive:\DoesNotExist.ps1 -ErrorAction Stop } | Should -Throw -ErrorId 'AstParserFailed,Get-FunctionInfo'
    }
}
