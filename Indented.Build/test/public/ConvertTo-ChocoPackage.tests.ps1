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
    Describe ConvertTo-ChocoPackage -Tag CI {
        It 'When an imported module is passed from Get-Module, creates a nupkg' {
            Get-Module Pester | ConvertTo-ChocoPackage -Path TestDrive:\

            'TestDrive:\Pester.*.nupkg' | Should -Exist
        }

        It 'When a module is passed from Get-Module -ListAvailable, creates a nupkg' {
            Get-Module Configuration -ListAvailable | ConvertTo-ChocoPackage -Path TestDrive:\

            'TestDrive:\Configuration.*.nupkg' | Should -Exist
        }

        It 'When a module is passed from Find-Module, downloads content and creates a nupkg' {
            Find-Module Indented.Net.IP | ConvertTo-ChocoPackage -Path TestDrive:\

            'TestDrive:\Indented.Net.IP.*.nupkg' | Should -Exist
        }

        It 'When a module is passed from Find-Module, and the module has dependencies, downloads module and dependencies' {
            Find-Module PSModuleDevelopment | ConvertTo-ChocoPackage -Path TestDrive:\

            'TestDrive:\PSModuleDevelopment.*.nupkg' | Should -Exist
            'TestDrive:\PSFramework.*.nupkg' | Should -Exist
        }
    }
}

