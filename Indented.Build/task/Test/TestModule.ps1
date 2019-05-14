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

        Import-Module $buildInfo.Path.Build.Manifest -Global -ErrorAction Stop
        $params = @{
            Script       = @{
                Path       = $path
                Parameters = @{
                    UseExisting = $true
                }
            }
            CodeCoverage           = $buildInfo.Path.Build.RootModule
            CodeCoverageOutputFile = Join-Path $buildInfo.Path.Build.Output 'pester-codecoverage.xml'
            OutputFile             = Join-Path $buildInfo.Path.Build.Output ('{0}-nunit.xml' -f $buildInfo.ModuleName)
            PassThru               = $true
        }
        Invoke-Pester @params
    }

    if ($buildInfo.BuildSystem -eq 'Desktop') {
        $pester = Start-Job -ArgumentList $buildInfo -ScriptBlock $script | Receive-Job -Wait
    } else {
        $pester = & $script -BuildInfo $buildInfo
    }
    $pester | Convert-CodeCoverage -BuildInfo $buildInfo

    $path = Join-Path $buildInfo.Path.Build.Output 'pester-output.xml'
    $pester | Export-CliXml $path
}