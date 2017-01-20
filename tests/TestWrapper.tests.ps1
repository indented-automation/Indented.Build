Get-ChildItem $psscriptroot\..\tasks -Filter *.ps1 -File | ForEach-Object {
    Describe $_.BaseName {
        $buildInfo = [PSCustomObject]@{
            State = 'OK'
        }

        if (Test-Path "$psscriptroot\$($_.BaseName).describe.ps1") {
            . $_.FullName

            . "$psscriptroot\$($_.BaseName).describe.ps1"
        } else {
            It 'Should have tests' {
                $false | Should Be $true
            }
        }
    }
}