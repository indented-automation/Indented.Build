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
    Describe Get-LevenshteinDistance -Tag CI {
        It 'When the difference string length is 0, returns the length of the reference string' {
            (Get-LevenshteinDistance -ReferenceString 'Hello' -DifferenceString '').Distance | Should -Be 'Hello'.Length
        }

        It 'When one character substitutions are required, returns a distance of 1' {
            (Get-LevenshteinDistance -ReferenceString 'Hello' -DifferenceString 'Helo').Distance | Should -Be 1
        }

        It 'When two character substitutions are required, returns a distance of 2' {
            (Get-LevenshteinDistance -ReferenceString 'Hello' -DifferenceString 'Helol').Distance | Should -Be 2
        }
    }
}
