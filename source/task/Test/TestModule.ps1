BuildTask TestModule -Stage Test -Properties @{
    Order          = 2
    Implementation = {
        if (-not (Get-ChildItem 'test' -Filter *.tests.ps1 -Recurse -File)) {
            throw 'The PS project must have tests!'    
        }

        Import-Module $buildInfo.ReleaseManifest -Global -ErrorAction Stop
        $params = @{
            Script       = 'test'
            OutputFile   = Join-Path $buildInfo.Output ('{0}.xml' -f $buildInfo.ModuleName)
            PassThru     = $true
        }
        $pester = Invoke-Pester @params

        if ($pester.FailedCount -gt 0) {
            throw 'PS unit tests failed'
        }
    }
}