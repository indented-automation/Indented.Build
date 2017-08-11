BuildTask UpdateMarkdownHelp -If { Get-Module platyPS -ListAvailable } -Stage Build -Definition {
    $exceptionMessage = powershell.exe -NoProfile -Command ('
        try {{
            $moduleInfo = Import-Module "{0}" -ErrorAction Stop -PassThru
            if ($moduleInfo.ExportedCommands.Count -gt 0) {{
                New-MarkdownHelp -Module "{1}" -OutputFolder "{2}\help" -Force
            }}

            exit 0
        }} catch {{
            $_.Exception.Message

            exit 1
        }}
    ' -f $buildInfo.Path.Manifest.FullName, $buildInfo.ModuleName, $buildInfo.Path.Source)

    if ($lastexitcode -ne 0) {
        throw $exceptionMessage
    }
}