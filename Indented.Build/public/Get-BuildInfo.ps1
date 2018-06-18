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

    [CmdletBinding()]
    [OutputType('BuildInfo')]
    param (
        # The tasks to execute, passed to Invoke-Build. BuildType is expected to be a broad description of the build, encompassing a set of tasks.
        [String[]]$BuildType = @('Setup', 'Build', 'Test'),

        # The release type. By default the release type is Build and the build version will increment.
        #
        # If the last commit message includes the phrase "major release" the release type will be reset to Major; If the last commit meessage includes "release" the releasetype will be reset to Minor.
        [ValidateSet('Build', 'Minor', 'Major', 'None')]
        [String]$ReleaseType = 'Build',

        # Generate build information for the specified path.
        [ValidateScript( { Test-Path $_ -PathType Container } )]
        [String]$Path = $pwd.Path
    )

    try {
        $Path = $pscmdlet.GetUnresolvedProviderPathFromPSPath($Path)
        Push-Location $Path

        $projectRoot = GetProjectRoot
        $projectRoot | GetSourcePath | ForEach-Object {
            $buildInfo = [PSCustomObject]@{
                ModuleName            = $moduleName = $_.Parent.GetDirectories($_.Name).Name
                BuildType             = $BuildType
                ReleaseType           = $ReleaseType
                BuildSystem           = GetBuildSystem
                Version               = '1.0.0'
                CodeCoverageThreshold = 0.8
                Repository            = [PSCustomObject]@{
                    Branch                = GetBranchName
                    LastCommitMessage     = GetLastCommitMessage
                }
                Path                  = [PSCustomObject]@{
                    ProjectRoot           = $projectRoot
                    Source                = $_
                    SourceManifest        = Join-Path $_ ('{0}.psd1' -f $moduleName)
                    Package               = ''
                    Output                = $output = [System.IO.DirectoryInfo](Join-Path $projectRoot 'output')
                    Nuget                 = Join-Path $output 'packages'
                    Manifest              = ''
                    RootModule            = ''
                }
            } | Add-Member -TypeName 'BuildInfo' -PassThru

            $buildInfo.Version = GetVersion $buildInfo.Path.SourceManifest | UpdateVersion -ReleaseType $ReleaseType

            $buildInfo.Path.Package = [System.IO.DirectoryInfo](Join-Path $buildInfo.Path.ProjectRoot $buildInfo.Version)
            if ($buildInfo.Path.ProjectRoot.Name -ne $buildInfo.ModuleName) {
                $buildInfo.Path.Package = [System.IO.DirectoryInfo][System.IO.Path]::Combine($buildInfo.Path.ProjectRoot, 'build', $buildInfo.ModuleName, $buildInfo.Version)
                $buildInfo.Path.Output = [System.IO.DirectoryInfo][System.IO.Path]::Combine($buildInfo.Path.ProjectRoot, 'build', 'output', $buildInfo.ModuleName)
                $buildInfo.Path.Nuget = [System.IO.DirectoryInfo][System.IO.Path]::Combine($buildInfo.Path.ProjectRoot, 'build', 'output', 'packages')
            }

            $buildInfo.Path.Manifest = [System.IO.FileInfo](Join-Path $buildInfo.Path.Package ('{0}.psd1' -f $buildInfo.ModuleName))
            $buildInfo.Path.RootModule = [System.IO.FileInfo](Join-Path $buildInfo.Path.Package ('{0}.psm1' -f $buildInfo.ModuleName))

            $buildInfo
        }
    } catch {
        $pscmdlet.ThrowTerminatingError($_)
    } finally {
        Pop-Location
    }
}