BuildTask UpdateMarkdownHelp -If { Get-Module platyPS -ListAvailable } -Stage Build -Definition {
    Start-Job -ArgumentList $buildInfo -ScriptBlock {
        param (
            $buildInfo
        )

        $path = Join-Path $buildInfo.Path.Source 'test*'

        if (Test-Path (Join-Path $path 'stub')) {
            Get-ChildItem (Join-Path $path 'stub') -Filter *.psm1 -Recurse -Depth 1 | ForEach-Object {
                Import-Module $_.FullName -Global -WarningAction SilentlyContinue
            }
        }

        try {
            $moduleInfo = Import-Module $buildInfo.Path.Manifest.FullName -ErrorAction Stop -PassThru
            if ($moduleInfo.ExportedCommands.Count -gt 0) {
                New-MarkdownHelp -Module $buildInfo.ModuleName -OutputFolder (Join-Path $buildInfo.Path.Source 'help') -Force
            }
        } catch {
            throw            
        }
    } | Receive-Job -Wait -ErrorAction Stop
}