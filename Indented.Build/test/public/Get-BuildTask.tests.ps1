#region:TestFileHeader
param (
    [Boolean]$UseExisting
)

if (-not $UseExisting) {
    $moduleBase = $psscriptroot.Substring(0, $psscriptroot.IndexOf("\test"))
    $stubBase = Resolve-Path (Join-Path $moduleBase "test*\stub\*")
    if ($null -ne $stubBase) {
        $stubBase | Import-Module -Force
    }

    Import-Module $moduleBase -Force
}
#endregion

InModuleScope Indented.Build {
    Describe Get-BuildTask {
        BeforeAll {
            Mock Get-ChildItem {
                [PSCustomObject]@{
                    FullName = {
                        [PSCustomObject]@{
                            Name = 'Compatible'
                            If   = { $true }
                        }
                    }
                }
                [PSCustomObject]@{
                    FullName = {
                        [PSCustomObject]@{
                            Name = 'NotCompatible'
                            If   = { $false }
                        }
                    }
                }
            }

            $buildInfo = [PSCustomObject]@{
                Path = [PSCustomObject]@{
                    Source = (Get-Item 'TestDrive:\')
                }
                PSTypeName = 'Indented.BuildInfo'
            }
        }

        BeforeEach {
            $Script:buildTaskCache = $null
        }

        It 'BuildTask: Lists compatible tasks: When BuildInfo is supplied and the task is compatible' {
            $buildTasks = Get-BuildTask -BuildInfo $buildInfo
            @($buildTasks).Count | Should -Be 1
            $buildTasks.Name | Should -Be 'Compatible'
        }

        It 'BuildTask: Lists all tasks: When ListAvailable is set' {
            $buildTasks = Get-BuildTask -ListAvailable
            @($buildTasks).Count | Should -Be 2
            $buildTasks.Name -contains 'Compatible' | Should -BeTrue
            $buildTasks.Name -contains 'NotCompatible' | Should -BeTrue
        }
    }
}