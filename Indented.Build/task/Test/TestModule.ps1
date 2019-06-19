BuildTask TestModule -Stage Test -Order 2 -Definition {
    # Run Pester tests.

    if (-not (Get-ChildItem (Resolve-Path (Join-Path $buildInfo.Path.Source.Module 'test*')).Path -Filter *.tests.ps1 -Recurse -File)) {
        throw 'The PS project must have tests!'
    }

    $script = {
        param (
            $buildInfo
        )

        $path = Join-Path $buildInfo.Path.Source.Module 'test*'

        if (Test-Path (Join-Path $path 'stub')) {
            Get-ChildItem (Join-Path $path 'stub') -Filter *.psm1 -Recurse -Depth 1 | ForEach-Object {
                Import-Module $_.FullName -Global -WarningAction SilentlyContinue
            }
        }

        # Prevent the default code coverage report appearing.
        Import-Module Pester
        & (Get-Module pester) { Set-Item function:\Write-CoverageReport -Value 'return' }

        Import-Module $buildInfo.Path.Build.Manifest -Global -ErrorAction Stop
        $params = @{
            Script     = @{
                Path       = $path
                Parameters = @{
                    UseExisting = $true
                }
            }
            OutputFile = Join-Path $buildInfo.Path.Build.Output ('{0}-nunit.xml' -f $buildInfo.ModuleName)
            PassThru   = $true
        }
        if (Test-Path $buildInfo.Path.Build.RootModule) {
            $params.Add('CodeCoverage', $buildInfo.Path.Build.RootModule)
            $params.Add('CodeCoverageOutputFile', (Join-Path $buildInfo.Path.Build.Output 'pester-codecoverage.xml'))
        }
        Invoke-Pester @params
    }

    if ($buildInfo.BuildSystem -eq 'Desktop') {
        $pester = Start-Job -ArgumentList $buildInfo -ScriptBlock $script | Receive-Job -Wait
    } else {
        $pester = & $script -BuildInfo $buildInfo
    }
    if ($pester.CodeCoverage) {
        $pester | Convert-CodeCoverage -BuildInfo $buildInfo

        $pester.CodeCoverage.MissedCommands | Format-Table @(
            @{ Name = 'File'; Expression = {
                if ($_.File -eq $buildInfo.Path.Build.RootModule) {
                    $buildInfo.Path.Build.RootModule.Name
                } else {
                    ($_.File -replace ([Regex]::Escape($buildInfo.Path.Source.Module))).TrimStart('\')
                }
            }}
            @{ Name = 'Name'; Expression = {
                if ($_.Class) {
                    '{0}\{1}' -f $_.Class, $_.Function
                } else {
                    $_.Function
                }
            }}
            'Line'
            'Command'
        )
    }

    $path = Join-Path $buildInfo.Path.Build.Output 'pester-output.xml'
    $pester | Export-CliXml $path
}