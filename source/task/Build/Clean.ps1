BuildTask Clean -Stage Build -Properties @{
    Order          = 0
    Implementation = {
        if (Get-Module $buildInfo.ModuleName) {
            Remove-Module $buildInfo.ModuleName
        }

        Get-ChildItem -Directory |
            Where-Object { [Version]::TryParse($_.Name, [Ref]$null) } |
            Remove-Item -Recurse -Force
        if (Test-Path $buildInfo.Output) {
            Remove-Item $buildInfo.Output -Recurse -Force
        }

        $null = New-Item $buildInfo.Output -ItemType Directory -Force
        $null = New-Item $buildInfo.ModuleBase -ItemType Directory -Force
    }
}