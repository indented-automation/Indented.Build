BuildTask TestModuleImport -Stage Test -Order 0 -Definition {
    Start-Job -ArgumentList $buildInfo -ScriptBlock {
        param (
            $buildInfo
        )

        Import-Module $buildInfo.Path.Manifest.FullName -ErrorAction Stop
    } | Receive-Job -Wait -ErrorAction Stop
}