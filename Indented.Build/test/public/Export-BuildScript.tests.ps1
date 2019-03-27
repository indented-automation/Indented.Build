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
    Describe Export-BuildScript {
        BeforeAll {
            Mock Get-BuildTask {
                [PSCustomObject]@{
                    Name       = 'CreatePackage'
                    Order      = 1
                    Stage      = 'Pack'
                    Definition = ''
                }
                [PSCustomObject]@{
                    Name       = 'NUnitTest'
                    Order      = 1
                    Stage      = 'Test'
                    Definition = ''
                }
                [PSCustomObject]@{
                    Name       = 'Compile'
                    Order      = 2
                    Stage      = 'Build'
                    If         = { $someVar -eq $true }
                    Definition = ''
                }
                [PSCustomObject]@{
                    Name       = 'Merge'
                    Order      = 1
                    Stage      = 'Build'
                    Definition = ''
                }
            }

            $buildInfo = [PSCustomObject]@{
                PSTypeName = 'Indented.BuildInfo'
            }
        }

        Context 'Command insertion' {
            BeforeAll {
                $script = Export-BuildScript -BuildInfo $buildInfo
            }

            It 'Inserts commands required by Get-BuildInfo' {
                $script | Should -Match 'function GetBuildSystem'
            }

            It 'Inserts Enabled-Metadata' {
                $script | Should -Match 'function Enable-Metadata'
            }

            It 'Inserts Get-BuildInfo' {
                $script | Should -Match 'function Get-BuildInfo'

            }

            It 'Inserts Get-BuildItem' {
                $script | Should -Match 'function Get-BuildItem'
            }
        }

        Context 'Task insertion' {
            BeforeAll {
                $script = Export-BuildScript -BuildInfo $buildInfo
            }

            It 'Inserts the task <Name> returned by Get-BuildTask' -TestCases @(
                @{ Name = 'CreatePackage' }
                @{ Name = 'NUnitTest' }
                @{ Name = 'Merge' }
                @{ Name = 'Compile' }
            ) {
                param (
                    $Name
                )

                $script | Should -Match "task $Name"
            }

            It 'Orders tasks based on Stage and Order' {
                $packIndex = $script.IndexOf('task CreatePackage')
                $mergeIndex = $script.IndexOf('task Merge')

                $mergeIndex | Should -BeLessThan $packIndex

                $compileIndex = $script.IndexOf('task Compile')

                $mergeIndex | Should -BeLessThan $compileIndex
            }
        }

        Context 'Summary tasks insertion' {
            BeforeAll {
                $script = Export-BuildScript -BuildInfo $buildInfo
            }

            It 'Inserts summary tasks' {
                $script | Should -Match 'task Build'
                $script | Should -Match 'task Test'
                $script | Should -Match 'task Pack'
            }

            It 'Inserts a default task' {
                $script | Should -Match 'task default'
            }
        }

        Context 'File generation' {
            BeforeAll {
                $path = 'TestDrive:\.build.ps1'
                $script = Export-BuildScript -BuildInfo $buildInfo -Path $path
            }

            It 'Output: File only' {
                $script | Should -BeNullOrEmpty
                $path | Should -Exist
            }
        }
    }
}