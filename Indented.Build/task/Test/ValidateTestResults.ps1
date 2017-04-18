BuildTask ValidateTestResults -Stage Test -Properties @{
    Order          = 4
    Implementation = {
        $testsFailed = $false

        $path = Join-Path $buildInfo.Output 'pester-output.xml'
        $pester  = Import-CliXml $path

        # PSScriptAnalyzer
        $path = Join-Path $buildInfo.Output 'psscriptanalyzer.csv'
        if ((Test-Path $path) -and ($testResults = Import-Csv $path)) {
            '{0} warnings were raised by PSScriptAnalyzer' -f @($testResults).Count
            $testsFailed = $true
        }

        # Pester tests
        if ($pester.FailedCount -gt 0) {
            '{0} of {1} pester tests are failing' -f $pester.FailedCount, $pester.TotalCount
            $testsFailed = $true
        }

        # Pester code coverage
        [Double]$codeCoverage = $pester.CodeCoverage.NumberOfCommandsExecuted / $pester.CodeCoverage.NumberOfCommandsAnalyzed
        $pester.CodeCoverage.MissedCommands | Export-Csv (Join-Path $buildInfo.Output 'CodeCoverage.csv') -NoTypeInformation

        if ($codecoverage -lt $buildInfo.CodeCoverageThreshold) {
            'Pester code coverage ({0:P}) is below threshold {1:P}.' -f $codeCoverage, $buildInfo.CodeCoverageThreshold
            $testsFailed = $true
        }

        # Solution tests
        Get-ChildItem $buildInfo.Output -Filter *.dll.xml | ForEach-Object {
            $report = [Xml](Get-Content $_.FullName -Raw)
            if ([Int]$report.'test-run'.failed -gt 0) {
                '{0} of {1} solution tests in {2} are failing' -f $report.'test-run'.failed,
                                                                  $report.'test-run'.total,
                                                                  $report.'test-run'.'test-suite'.name
                $testsFailed = $true
            }
        }

        if ($testsFailed) {
            throw 'Test result validation failed'
        }
    }
}