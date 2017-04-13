BuildTask TestModule -Stage Test -Properties @{
    Implementation = {
        if (-not (Get-ChildItem 'test' -Filter *.tests.ps1 -Recurse -File)) {
            throw 'The PS project must have tests!'    
        }

        Import-Module $buildInfo.ReleaseManifest -ErrorAction Stop
        $params = @{
            Script       = 'test'
            CodeCoverage = $buildInfo.ReleaseRootModule
            OutputFile   = Join-Path $buildInfo.Output ('{0}.xml' -f $buildInfo.ModuleName)
            PassThru     = $true
        }
        $pester = Invoke-Pester @params

        if ($pester.FailedCount -gt 0) {
            throw 'PS unit tests failed'
        }

        [Double]$codeCoverage = $pester.CodeCoverage.NumberOfCommandsExecuted / $pester.CodeCoverage.NumberOfCommandsAnalyzed
        $pester.CodeCoverage.MissedCommands | Export-Csv (Join-Path $buildInfo.Output 'CodeCoverage.csv') -NoTypeInformation

        if ($codecoverage -lt $buildInfo.CodeCoverageThreshold) {
            $message = 'Code coverage ({0:P}) is below threshold {1:P}.' -f $codeCoverage, $buildInfo.CodeCoverageThreshold 
            throw $message
        }
    }
}