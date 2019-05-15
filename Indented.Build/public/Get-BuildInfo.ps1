function Get-BuildInfo {
    <#
    .SYNOPSIS
        Get properties required to build the project.
    .DESCRIPTION
        Get the properties required to build the project, or elements of the project.
    .EXAMPLE
        Get-BuildInfo

        Get build information for the current or any child directories.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [CmdletBinding()]
    [OutputType('Indented.BuildInfo')]
    param (
        [String]$ModuleName = '*',

        # Generate build information for the specified path.
        [ValidateScript( { Test-Path $_ -PathType Container } )]
        [String]$ProjectRoot = $pwd.Path
    )

    $ProjectRoot = $pscmdlet.GetUnresolvedProviderPathFromPSPath($ProjectRoot)
    Get-ChildItem $ProjectRoot\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        ($moduleManifest = Test-ModuleManifest $_.FullName -ErrorAction SilentlyContinue)
    } | ForEach-Object {
        $configOverridePath = Join-Path $_.Directory.FullName 'buildConfig.psd1'
        if (Test-Path $configOverridePath) {
            $config = Import-PowerShellDataFile $configOverridePath
        } else {
            $config = @{}
        }

        try {
            [PSCustomObject]@{
                ModuleName  = $moduleName = $_.BaseName
                Version     = $version = $moduleManifest.Version
                Config      = [PSCustomObject]@{
                    CodeCoverageThreshold = (0.8, $config.CodeCoverageThreshold)[$null -ne $config.CodeCoverageThreshold]
                    EndOfLineChar         = ([Environment]::NewLine, $config.EndOfLineChar)[$null -ne $config.EndOfLineChar]
                    License               = ('MIT', $config.License)[$null -ne $config.License]
                    CreateChocoPackage    = ($false, $config.CreateChocoPackage)[$null -ne $config.CreateChocoPackage]
                }
                Path        = [PSCustomObject]@{
                    ProjectRoot = $ProjectRoot
                    Source      = [PSCustomObject]@{
                        Module   = $_.Directory
                        Manifest = $_
                    }
                    Build       = [PSCustomObject]@{
                        Module     = $module = [System.IO.DirectoryInfo][System.IO.Path]::Combine($ProjectRoot, 'build', $moduleName, $version)
                        Manifest   = [System.IO.FileInfo](Join-Path $module ('{0}.psd1' -f $moduleName))
                        RootModule = [System.IO.FileInfo](Join-Path $module ('{0}.psm1' -f $moduleName))
                        Output     = [System.IO.DirectoryInfo][System.IO.Path]::Combine($ProjectRoot, 'build\output', $moduleName)
                        Package    = [System.IO.DirectoryInfo][System.IO.Path]::Combine($ProjectRoot, 'build\packages')
                    }
                }
                BuildSystem = GetBuildSystem
                PSTypeName  = 'Indented.BuildInfo'
            }
        } catch {
            Write-Error -ErrorRecord $_
        }
    } | Where-Object ModuleName -like $ModuleName
}