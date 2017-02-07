Mock Test-Path { return $true }
Mock Remove-Item { }
Mock New-Item { }

Clean

It 'Deletes build\package if it exists' {
    Assert-MockCalled Remove-Item -Exactly 1
}

It 'Creates the build\package folder' {
    Assert-MockCalled New-Item -Exactly 1
}


Context 'build\package does not exist' {
    Mock Test-Path { return $false }

    Clean

    It 'Does not attempt to remove build\packge if it does not exist' {
        Assert-MockCalled Remove-Item -Exactly 0
    }
}