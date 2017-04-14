BuildTask ModuleCodeCoverage -Stage Test -Properties @{
    Order          = 3
    Implementation = {
        Import-Module $buildInfo.ReleaseManifest -Global -ErrorAction Stop
        $params = @{
            Script       = 'test'
            CodeCoverage = $buildInfo.ReleaseRootModule
            OutputFile   = Join-Path $buildInfo.Output ('{0}.xml' -f $buildInfo.ModuleName)
            Show         = 'None'
            PassThru     = $true
        }
        $pester = Invoke-Pester @params

        [Double]$codeCoverage = $pester.CodeCoverage.NumberOfCommandsExecuted / $pester.CodeCoverage.NumberOfCommandsAnalyzed
        $pester.CodeCoverage.MissedCommands | Export-Csv (Join-Path $buildInfo.Output 'CodeCoverage.csv') -NoTypeInformation

        if ($codecoverage -lt $buildInfo.CodeCoverageThreshold) {
            $message = 'Code coverage ({0:P}) is below threshold {1:P}.' -f $codeCoverage, $buildInfo.CodeCoverageThreshold 
            throw $message
        }
    }
}