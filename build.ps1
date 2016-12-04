#requires -Module psake, Configuration, pester

# Self-update
Get-ChildItem 'C:\Development\BuildTools' |
    Where-Object {
        (
            $_.Name -like 'build*' -or
            $_.Name -like 'nuget.*'
        ) -and
        (
            -not (Test-Path "$psscriptroot\$($_.Name)") -or 
            $_.LastWriteTime -gt (Get-Item "$psscriptroot\$($_.Name)").LastWriteTime
        )
    } | ForEach-Object {
        Write-Host "Updating $($_.Name)" -ForegroundColor Green

        Copy-Item $_.FullName -Destination $psscriptroot
    }

Include "$psscriptroot\build_utils.ps1"
Include "$psscriptroot\build_tasks.ps1"