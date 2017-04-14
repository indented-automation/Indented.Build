BuildTask TestModule -Stage Test -Properties @{
    Order          = 2
    Implementation = {
        $erroractionpreference = 'Stop'
        try {
            if (-not (Get-ChildItem (Join-Path $buildInfo.Source 'test') -Filter *.tests.ps1 -Recurse -File)) {
                throw 'The PS project must have tests!'    
            }

            Import-Module $buildInfo.ReleaseManifest -Global -ErrorAction Stop
            $params = @{
                Script       = Join-Path $buildInfo.Source 'test'
                OutputFile   = Join-Path $buildInfo.Output ('{0}.xml' -f $buildInfo.ModuleName)
                PassThru     = $true
            }
            $pester = Invoke-Pester @params

            if (Get-Command Add-AppveyorCompilationMessage -ErrorAction SilentlyContinue) {
                $params = @{
                    Message =  ('{0} of {1} tests passed' -f @($pester.PassedScenarios).Count, (@($pester.PassedScenarios).Count + @($pester.FailedScenarios).Count))
                    Category = 'Information'
                }
                if (($pester.FailedScenarios).Count -gt 0) {
                    $params.Category = 'Warning'
                }
                Add-AppveyorCompilationMessage @params
            }

            if ($pester.FailedCount -gt 0) {
                throw 'PS unit tests failed'
            }
        } catch {
            throw
        }
    }
}