BuildTask UpdateMarkdownHelp -Stage Build -If {
    Get-Module platyPS -ListAvailable
} -Definition {
    Start-Job -ArgumentList $buildInfo -ScriptBlock {
        param (
            $buildInfo
        )

        $path = Join-Path $buildInfo.Path.Source.Module 'test*'

        if (Test-Path (Join-Path $path 'stub')) {
            Get-ChildItem (Join-Path $path 'stub') -Filter *.psm1 -Recurse -Depth 1 | ForEach-Object {
                Import-Module $_.FullName -Global -WarningAction SilentlyContinue
            }
        }

        try {
            $moduleInfo = Import-Module $buildInfo.Path.Build.Manifest.FullName -ErrorAction Stop -PassThru
            if ($moduleInfo.ExportedCommands.Count -gt 0) {
                New-MarkdownHelp -Module $buildInfo.ModuleName -OutputFolder (Join-Path $buildInfo.Path.Source.Module 'help') -Force
            }
        } catch {
            throw
        }
    } | Receive-Job -Wait -ErrorAction Stop
}