InModuleScope Indented.Build {
    Describe Start-Build {
        BeforeAll {
            Mock Get-BuildInfo {
                [PSCustomObject]@{} | Add-Member -TypeName 'BuildInfo' -PassThru
            }
            Mock Get-BuildTask {
                [PSCustomObject]@{} | Add-Member -TypeName 'BuildTask' -PassThru
            }
            Mock Invoke-BuildTask {
                $taskInfo.Value = [PSCustomObject]@{
                    Result = 'Success'
                }
            }
            Mock Write-Message
            Mock Write-Progress
        }

        Context 'Successful build' {
            It 'Command: Calls Invoke-Build for each task' {
                Start-Build
                Assert-MockCalled Invoke-BuildTask
            }

            It 'Output: Returns TaskInfo: When PassThru is set' {
                $taskInfo = Start-Build -PassThru
                $taskInfo.Result | Should -Be 'Success'
            }
        }

        Context 'Failed build' {
            BeforeAll {
                Mock Invoke-BuildTask {
                    $taskInfo.Value = [PSCustomObject]@{
                        Result = 'Failed'
                        Errors = 'Message'
                    }
                }
            }

            It 'Error: Non-Terminating: When a build fails' {
                { Start-Build -ErrorAction SilentlyContinue } | Should -Not -Throw
                { Start-Build -ErrorAction Stop } | Should -Throw
            }
        }
    }
}