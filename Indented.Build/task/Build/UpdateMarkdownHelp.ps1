BuildTask UpdateMarkdownHelp -If { Get-Module platyPS -ListAvailable } -Stage Build -Definition {
    Start-Job -ArgumentList $buildInfo -ScriptBlock {
        param (
            $buildInfo
        )

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