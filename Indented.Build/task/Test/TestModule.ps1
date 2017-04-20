BuildTask TestModule -Stage Test -Properties @{
    Order          = 2
    Implementation = {
        if (-not (Get-ChildItem (Join-Path $buildInfo.Source 'test') -Filter *.tests.ps1 -Recurse -File)) {
            throw 'The PS project must have tests!'    
        }

        $invokePester = {
            param (
                $buildInfo
            )

            $path = Join-Path $buildInfo.Source 'test'

            if (Test-Path (Join-Path $path 'stub')) {
                Get-ChildItem (Join-Path $path 'stub') -Filter *.psm1 | ForEach-Object {
                    Import-Module $_.FullName -Global -WarningAction SilentlyContinue
                }
            }

            Import-Module $buildInfo.ReleaseManifest -Global -ErrorAction Stop
            $params = @{
                Script       = $path
                CodeCoverage = $buildInfo.ReleaseRootModule
                OutputFile   = Join-Path $buildInfo.Output ('{0}.xml' -f $buildInfo.ModuleName)
                PassThru     = $true
            }
            Invoke-Pester @params
        }
        if ($buildInfo.IsAdministrator -and -not (Test-CIServer)) {
            $pester = Invoke-Command $invokePester -ArgumentList $buildInfo -ComputerName $env:COMPUTERNAME
        } else {
            $pester = & $invokePester $buildInfo
        }
        
        $path = Join-Path $buildInfo.Output 'pester-output.xml'
        $pester | Export-CliXml $path
    }
}