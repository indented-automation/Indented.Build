InModuleScope Indented.Build {
    Describe Invoke-BuildTask {
        BeforeAll {
            Mock Write-Message
            Mock Write-Progress

            $taskInfo = New-Object PSObject
            $params = @{
                BuildTask = [PSCustomObject]@{
                    Name       = 'TaskName'
                    Definition = { 'TaskDefinition' }
                } | Add-Member -TypeName 'BuildTask' -PassThru
                BuildInfo = [PSCustomObject]@{} | Add-Member -TypeName 'BuildInfo' -PassThru
                TaskInfo  = [Ref]$taskInfo
            }
        }

        Context 'Successful tasks' {
            BeforeAll {
                $output = Invoke-BuildTask @params
            }
            
            It 'Output: Returns values from the task' {
                $output | Should -Be 'TaskDefinition'
            }

            It 'TaskInfo: Fills the PSObject' {
                $taskInfo.Name | Should -Be 'TaskName'
                $taskInfo.Result | Should -Be 'Success'
            }

            It 'Information: Writes task state' {
                Assert-MockCalled Write-Message -Times 4
            }
        }

        Context 'Failed tasks' {
            It 'TaskInfo: Shows error information' {
                $errorParams = $params.Clone()
                $errorParams.BuildTask.Definition = { throw 'Message' }

                $output = Invoke-BuildTask @errorParams

                $taskInfo.Result | Should -Be 'Failed'
                $taskInfo.Errors | Should -Be 'Message'
            }
        }

        Context 'Quiet' {
            It 'Information: Does not write messages: When Quiet is set' {
                Invoke-BuildTask @params -Quiet
                Assert-MockCalled Write-Message -Exactly 0
            }
        }

    }
}