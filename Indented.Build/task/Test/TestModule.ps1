BuildTask TestModule -Stage Test -Order 2 -Definition {
    if (-not (Get-ChildItem (Resolve-Path (Join-Path $buildInfo.Path.Source 'test*')).Path -Filter *.tests.ps1 -Recurse -File)) {
        throw 'The PS project must have tests!'    
    }

    $invokePester = {
        param (
            $buildInfo
        )

        $path = (Resolve-Path (Join-Path $buildInfo.Path.Source 'test*')).Path

        if (Test-Path (Join-Path $path 'stub')) {
            Get-ChildItem (Join-Path $path 'stub') -Filter *.psm1 | ForEach-Object {
                Import-Module $_.FullName -Global -WarningAction SilentlyContinue
            }
        }

        Import-Module $buildInfo.Path.Manifest -Global -ErrorAction Stop
        $params = @{
            Script       = $path
            CodeCoverage = $buildInfo.Path.RootModule
            OutputFile   = Join-Path $buildInfo.Path.Output ('{0}-nunit.xml' -f $buildInfo.ModuleName)
            PassThru     = $true
        }
        Invoke-Pester @params
    }
    if ($buildInfo.IsAdministrator -and $buildInfo.BuildSystem -eq 'Unknown') {
        $pester = Invoke-Command $invokePester -ArgumentList $buildInfo -ComputerName $env:COMPUTERNAME
    } else {
        $pester = & $invokePester $buildInfo
    }
    
    $path = Join-Path $buildInfo.Path.Output 'pester-output.xml'
    $pester | Export-CliXml $path
}