#region:TestFileHeader
param (
   [Boolean]$UseExisting
)

if (-not $UseExisting) {
   $moduleBase = $psscriptroot.Substring(0, $psscriptroot.IndexOf("\\test"))
   $stubBase = Resolve-Path (Join-Path $moduleBase "test*\\stub\\*")
   if ($null -ne $stubBase) {
       $stubBase | Import-Module -Force
   }

   Import-Module $moduleBase -Force
}
#endregion

InModuleScope Indented.Build {
    Describe Enable-Metadata {
        BeforeAll {
            Mock Get-Content {
                '@{
                    Enabled = 1
                    # Disabled = 2
                    # Duplicate = 3
                    ChildNode = @{
                        # Duplicate = 3
                    }
                }'
            }
            Mock Set-Content
            Mock Test-Path { $true }

            $path = 'TestDrive:\manifest.psd1'
        }

        Context 'Value exists and is enabled' {
            BeforeAll {
                Mock Get-Metadata

                $return = Enable-Metadata -PropertyName Enabled -Path $path
            }

            It 'Output: True when the value was present and already enabled' {
                $return | Should -Be $true
            }

            It 'Command: Does not call Get-Content or Set-Content' {
                Assert-MockCalled Get-Content -Times 0
                Assert-MockCalled Set-Content -Times 0
            }
        }

        Context 'Value exists and is commented / disabled' {
            BeforeAll {
                Mock Get-Metadata {
                    throw [System.Management.Automation.ItemNotFoundException]::new('Not found')
                }

                $return = Enable-Metadata -PropertyName Disabled -Path $path
            }

            It 'Output: True when the value was commented and updated' {
                $return | Should -Be $true
            }

            It 'Command: Calls Get-Content and Set-Content' {
                Assert-MockCalled Get-Content -Times 1 -Exactly
                Assert-MockCalled Set-Content -Times 1 -Exactly
            }
        }

        Context 'Value exists in more than one location' {
            BeforeAll {
                Mock Get-Metadata {
                    throw [System.Management.Automation.ItemNotFoundException]::new('Not found')
                }

                $return = Enable-Metadata -PropertyName Duplicate -Path $path -WarningVariable warning -WarningAction SilentlyContinue
            }

            It 'Output: False when the value is ambiguous' {
                $return | Should -Be $false
            }

            It 'Command: Calls Get-Content' {
                Assert-MockCalled Get-Content -Times 1 -Exactly
            }

            It 'Command: Does not call Set-Content' {
                Assert-MockCalled Set-Content -Times 0
            }

            It 'Command: Calls Write-Warning' {
                $warning | Should -BeLike 'Found more than one*'
            }
        }

        Context 'Value does not exist' {
            BeforeAll {
                Mock Get-Metadata {
                    throw [System.Management.Automation.ItemNotFoundException]::new('Not found')
                }

                $return = Enable-Metadata -PropertyName None -Path $path -WarningVariable warning -WarningAction SilentlyContinue
            }

            It 'Output: False when the value does not exist' {
                $return | Should -Be $false
            }

            It 'Command: Calls Get-Content' {
                Assert-MockCalled Get-Content -Times 1 -Exactly
            }

            It 'Command: Does not call Set-Content' {
                Assert-MockCalled Set-Content -Times 0
            }

            It 'Command: Calls Write-Warning' {
                $warning | Should -BeLike 'Cannot find disabled property*'
            }
        }
    }
}