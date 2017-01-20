Push-Location TestDrive:\

New-Item source\public -ItemType Directory -Force
'Get-Process | Out-Null' | Out-File 'TestDrive:\source\public\Do-Nothing.ps1'

TestSyntax

It 'Does not modify build state if there are no syntax errors' {
    $buildInfo.State | Should Be 'OK'
}

Context 'Syntax error handling' {
    'Get-Process | Out-Null ==' | Out-File 'TestDrive:\source\public\Do-Nothing.ps1'

    It 'Fails the build if any script (which will be merged) contains errors' {

    }
}

Pop-Location