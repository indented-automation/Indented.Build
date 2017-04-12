BuildTask TestModuleImport -Stage Test -Properties @{
    Implementation = {
        $argumentList += '-NoProfile', '-Command', ('
            try {{
                Import-Module "{0}" -ErrorAction Stop
            }} catch {{
                $_.Exception.Message
                exit 1
            }}
            exit 0
        ' -f $buildInfo.Manifest)

        & powershell.exe $argumentList
    }
}