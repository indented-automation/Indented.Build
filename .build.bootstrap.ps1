# Provides a build of the module with minimal validation / discovery.

task Build Setup,
           Clean,
           CopyModuleFiles,
           Merge,
           UpdateMetadata,
           UpdateBuildScript

task Setup GetBuildInfo,
           InstallRequiredModules

function Get-BuildItem {
    <#
    .SYNOPSIS
        Get source items.
    .DESCRIPTION
        Get items from the source tree which will be consumed by the build process.

        This function centralises the logic required to enumerate files and folders within a project.
    #>

    [CmdletBinding()]
    [OutputType([System.IO.FileInfo], [System.IO.DirectoryInfo])]
    param (
        # Gets items by type.
        #
        #   ShouldMerge - *.ps1 files from enum*, class*, priv*, pub* and InitializeModule if present.
        #   Static      - Files which are not within a well known top-level folder. Captures help content in en-US, format files, configuration files, etc.
        [Parameter(Mandatory)]
        [ValidateSet('ShouldMerge', 'Static')]
        [String]$Type,

        # BuildInfo is used to determine the source path.
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSTypeName('Indented.BuildInfo')]
        [PSObject]$BuildInfo,

        # Exclude script files containing PowerShell classes.
        [Switch]$ExcludeClass
    )

    try {
        Push-Location $buildInfo.Path.Source.Module

        $itemTypes = [Ordered]@{
            enumeration    = 'enum*'
            class          = 'class*'
            private        = 'priv*'
            public         = 'pub*'
            initialisation = 'InitializeModule.ps1'
        }

        if ($Type -eq 'ShouldMerge') {
            foreach ($itemType in $itemTypes.Keys) {
                if ($itemType -ne 'class' -or ($itemType -eq 'class' -and -not $ExcludeClass)) {
                    Get-ChildItem $itemTypes[$itemType] -Recurse -ErrorAction SilentlyContinue |
                        Where-Object { -not $_.PSIsContainer -and $_.Extension -eq '.ps1' -and $_.Length -gt 0 }
                }
            }
        } elseif ($Type -eq 'Static') {
            [String[]]$exclude = $itemTypes.Values + '*.config', 'test*', 'doc*', 'help', '.build*.ps1', 'build.psd1'

            foreach ($item in Get-ChildItem) {
                $shouldExclude = $false

                foreach ($exclusion in $exclude) {
                    if ($item.Name -like $exclusion) {
                        $shouldExclude = $true
                    }
                }

                if (-not $shouldExclude) {
                    $item
                }
            }
        }
    } catch {
        $pscmdlet.ThrowTerminatingError($_)
    } finally {
        Pop-Location
    }
}

task GetBuildInfo {
    $Script:buildInfo = [PSCustomObject]@{
        ModuleName = 'Indented.Build'
        Version    = [Version]'1.0.0'
        Config      = [PSCustomObject]@{
            EndOfLineChar = ([Environment]::NewLine, $config.EndOfLineChar)[$null -ne $config.EndOfLineChar]
        }
        Path       = [PSCustomObject]@{
            ProjectRoot = $psscriptroot
            Source      = [PSCustomObject]@{
                Module   = [System.IO.DirectoryInfo](Join-Path $psscriptroot 'Indented.Build')
                Manifest = [System.IO.DirectoryInfo](Join-Path $psscriptroot 'Indented.Build\Indented.Build.psd1')
            }
            Build       = [PSCustomObject]@{
                Module     = [System.IO.DirectoryInfo](Join-Path $psscriptroot 'build\Indented.Build\1.0.0')
                Manifest   = [System.IO.FileInfo](Join-Path $psscriptroot 'build\Indented.Build\1.0.0\Indented.Build.psd1')
                RootModule = [System.IO.FileInfo](Join-Path $psscriptroot 'build\Indented.Build\1.0.0\Indented.Build.psm1')
                Output     = [System.IO.DirectoryInfo](Join-Path $psscriptroot 'build\output')
                Package    = [System.IO.DirectoryInfo](Join-Path $psscriptroot 'build\packages')
            }
        }
        PSTypeName = 'Indented.BuildInfo'
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
    $erroractionprefence = 'Stop'

    try {
        if (Get-Module $buildInfo.ModuleName) {
            Remove-Module $buildInfo.ModuleName
        }

        if (Test-Path $buildInfo.Path.Build.Module.Parent.FullName) {
            Remove-Item $buildInfo.Path.Build.Module.Parent.FullName -Recurse -Force
        }

        $nupkg = Join-Path $buildInfo.Path.Build.Package ('{0}.*.nupkg' -f $buildInfo.ModuleName)
        if (Test-Path $nupkg) {
            Remove-Item $nupkg
        }

        $output = Join-Path $buildInfo.Path.Build.Output ('{0}*' -f $buildInfo.ModuleName)
        if (Test-Path $output) {
            Remove-Item $output
        }

        $null = New-Item $buildInfo.Path.Build.Module -ItemType Directory -Force
        $null = New-Item $buildInfo.Path.Build.Package -ItemType Directory -Force

        if (-not (Test-Path $buildInfo.Path.Build.Output)) {
            $null = New-Item $buildInfo.Path.Build.Output -ItemType Directory -Force
        }
    } catch {
        throw
    }
}

task CopyModuleFiles {
    try {
        $buildInfo |
            Get-BuildItem -Type Static |
            Copy-Item -Destination $buildInfo.Path.Build.Module -Recurse -Force
    } catch {
        throw
    }
}

task Merge {
    $writer = [System.IO.StreamWriter][System.IO.File]::Create($buildInfo.Path.Build.RootModule)

    $usingStatements = [System.Collections.Generic.HashSet[String]]::new()

    $buildInfo | Get-BuildItem -Type ShouldMerge | ForEach-Object {
        $functionDefinition = Get-Content $_.FullName | ForEach-Object {
            if ($_ -match '^using (namespace|assembly)') {
                $null = $usingStatements.Add($_)
            } else {
                $_.TrimEnd()
            }
        }
        $writer.Write(($functionDefinition -join $buildInfo.Config.EndOfLineChar).Trim())
        $writer.Write($buildInfo.Config.EndOfLineChar * 2)
    }

    if (Test-Path (Join-Path $buildInfo.Path.Source.Module 'InitializeModule.ps1')) {
        $writer.WriteLine('InitializeModule')
    }

    $writer.Close()

    $rootModule = (Get-Content $buildInfo.Path.Build.RootModule -Raw).Trim()
    if ($usingStatements.Count -gt 0) {
        # Add "using" statements to be start of the psm1
        $rootModule = $rootModule.Insert(
            0,
            ($buildInfo.Config.EndOfLineChar * 2)
        ).Insert(
            0,
            (($usingStatements | Sort-Object) -join $buildInfo.Config.EndOfLineChar)
        )
    }
    Set-Content -Path $buildInfo.Path.Build.RootModule -Value $rootModule -NoNewline
}

task UpdateMetadata {
    try {
        $path = $buildInfo.Path.Build.Manifest

        # Version
        Update-Metadata $path -PropertyName ModuleVersion -Value $buildInfo.Version

        # RootModule
        if (Enable-Metadata $path -PropertyName RootModule) {
            Update-Metadata $path -PropertyName RootModule -Value $buildInfo.Path.Build.RootModule.Name
        }

        # FunctionsToExport
        $functionsToExport = Get-ChildItem (Join-Path $buildInfo.Path.Source.Module 'pub*') -Filter '*.ps1' -Recurse |
            Get-FunctionInfo |
            Select-Object -ExpandProperty Name
        if ($functionsToExport) {
            if (Enable-Metadata $path -PropertyName FunctionsToExport) {
                Update-Metadata $path -PropertyName FunctionsToExport -Value $functionsToExport
            }
        }

        # FormatsToProcess
        if (Test-Path (Join-Path $buildInfo.Path.Build.Module '*.Format.ps1xml')) {
            if (Enable-Metadata $path -PropertyName FormatsToProcess) {
                Update-Metadata $path -PropertyName FormatsToProcess -Value (Get-Item (Join-Path $buildInfo.Path.Build.Module '*.Format.ps1xml')).Name
            }
        }
    } catch {
        throw
    }
}

task UpdateBuildScript {
    Import-Module $buildInfo.Path.Build.Manifest -Global -Force
    Export-BuildScript -BuildSystem AppVeyor -Path (Join-Path $buildInfo.Path.ProjectRoot '.build.ps1')
}