InModuleScope Indented.Build {
    Describe Write-Message {
        BeforeAll {
            Mock Write-Host
        }

        Context 'Simple messages' {
            It 'Host: Writes a message' {
                Write-Message -Object 'Message'
                Assert-MockCalled Write-Host
            }
        }

        Context 'Padded messages' {
            It 'Host: Writes a message with padding either side: When WithPadding is set' {
                Write-Message -Object 'Message' -WithPadding
                Assert-MockCalled Write-Host -Times 3
            }
        }

        Context 'Quiet' {
            It 'Host: Does not write a message: When Quiet is set' {
                Write-Message -Object 'Nothing' -Quiet
                Assert-MockCalled Write-Host -Times 0
            }
        }
    }
}