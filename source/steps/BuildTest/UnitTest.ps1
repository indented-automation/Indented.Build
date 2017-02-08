function UnitTest {
    # Execute unit tests
    # Note: These tests are being executed against the Packaged module, not the code in the repository.

    [BuildStep('BuildTest')]
    param( )

    if (-not (Test-Path 'tests\unit\*')) {
        throw 'The project must have tests!'    
    }

    Import-Module $buildInfo.Manifest -ErrorAction Stop
    $pester = Invoke-Pester -Script 'tests\unit' -CodeCoverage $buildInfo.RootModule -PassThru

    if ($pester.FailedCount -gt 0) {
        throw 'Unit tests failed'
    }

    [Double]$codeCoverage = $pester.CodeCoverage.NumberOfCommandsExecuted / $pester.CodeCoverage.NumberOfCommandsAnalyzed
    $pester.CodeCoverage.MissedCommands | Export-Csv (Join-Path $buildInfo.Output 'CodeCoverage.csv') -NoTypeInformation

    if ($codecoverage -lt $buildInfo.CodeCoverageThreshold) {
        $message = 'Code coverage ({0:P}) is below threshold {1:P}.' -f $codeCoverage, $buildInfo.CodeCoverageThreshold 
        throw $message
    } 
}