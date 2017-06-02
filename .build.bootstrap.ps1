# Provides a build of the module with minimal validation / discovery.

task Build Setup,
           Clean,
           CopyModuleFiles,
           Merge,
           UpdateMetadata

task Setup GetBuildInfo,
           InstallRequiredModules

task GetBuildInfo {
    $Script:buildInfo = [PSCustomObject]@{
        ModuleName = 'Indented.Build'
        Version    = [Version]'0.0.0'
        Path       = [PSCustomObject]@{
            Source     = [System.IO.DirectoryInfo]"$psscriptroot\Indented.Build"
            Package    = [System.IO.DirectoryInfo]"$psscriptroot\0.0.0"
            RootModule = [System.IO.FileInfo]"$psscriptroot\0.0.0\Indented.Build.psm1"
            Manifest   = [System.IO.FileInfo]"$psscriptroot\0.0.0\Indented.Build.psd1"
        }
    }
}

task InstallRequiredModules {
    $erroractionpreference = 'Stop'
    try {
        $nugetPackageProvider = Get-PackageProvider NuGet -ErrorAction SilentlyContinue
        if (-not $nugetPackageProvider -or $nugetPackageProvider.Version -lt [Version]'2.8.5.201') {
            $null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        }
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

        'Configuration', 'Pester' | Where-Object { -not (Get-Module $_ -ListAvailable) } | ForEach-Object {
            Install-Module $_ -Scope CurrentUser
        }
        Import-Module 'Configuration', 'Pester' -Global
    } catch {
        throw
    }
}

task Clean {
    if (Get-Module $buildInfo.ModuleName) {
        Remove-Module $buildInfo.ModuleName
    }

    Get-ChildItem $buildInfo.Path.Package.Parent.FullName -Directory -ErrorAction SilentlyContinue |
        Where-Object { [Version]::TryParse($_.Name, [Ref]$null) } |
        Remove-Item -Recurse -Force

    $null = New-Item $buildInfo.Path.Package -ItemType Directory -Force
}

task CopyModuleFiles {
    Copy-Item (Join-Path $buildInfo.Path.Source $buildInfo.Path.Manifest.Name) $buildInfo.Path.Package -Recurse -Force
    Copy-Item (Join-Path $buildInfo.Path.Source 'task') $buildInfo.Path.Package -Recurse -Force
}

task Merge {
    $fileStream = [System.IO.File]::Create($buildInfo.Path.RootModule)
    $writer = New-Object System.IO.StreamWriter($fileStream)

    $usingStatements = New-Object System.Collections.Generic.List[String]

    foreach ($name in 'enumeration', 'private', 'public') {
        Get-ChildItem (Join-Path $buildInfo.Path.Source $name) -Filter *.ps1 -File -Recurse | ForEach-Object {
            $functionDefinition = Get-Content $_.FullName | ForEach-Object {
                if ($_ -match '^using') {
                    $usingStatements.Add($_)
                } else {
                    $_.TrimEnd()
                }
            } | Out-String
            $writer.WriteLine($functionDefinition.Trim())
            $writer.WriteLine()
        }
    }

    $writer.Close()

    $rootModule = (Get-Content $buildInfo.Path.RootModule -Raw).Trim()
    if ($usingStatements.Count -gt 0) {
        # Add "using" statements to be start of the psm1
        $rootModule = $rootModule.Insert(0, "`r`n`r`n").Insert(
            0,
            (($usingStatements.ToArray() | Sort-Object | Get-Unique) -join "`r`n")
        )
    }
    Set-Content -Path $buildInfo.Path.RootModule -Value $rootModule -NoNewline
}

task UpdateMetadata {
    try {
        $path = $buildInfo.Path.Manifest

        # Version
        Update-Metadata $path -PropertyName ModuleVersion -Value $buildInfo.Version
        
        # RootModule
        Update-Metadata $path -PropertyName RootModule -Value $buildInfo.Path.RootModule.Name

        # FunctionsToExport
        Update-Metadata $path -PropertyName FunctionsToExport -Value (
            (Get-ChildItem (Join-Path $buildInfo.Path.Source 'public') -Filter '*.ps1' -File -Recurse).BaseName
        )
    } catch {
        throw
    }
}