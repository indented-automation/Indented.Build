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
        [ValidateSet('Build', 'Minor', 'Major')]
        [String]$ReleaseType = 'Build',

        # Generate build informatio for the specified path.
        [ValidateScript( { Test-Path $_ -PathType Container } )]
        [String]$Path = $pwd.Path
    )

    try {
        $Path = $pscmdlet.GetUnresolvedProviderPathFromPSPath($Path)

        Push-Location $Path

        $buildInfo = [PSCustomObject]@{
            ModuleName            = ''
            BuildType             = $BuildType
            ReleaseType           = $ReleaseType
            BuildSystem           = GetBuildSystem
            Version               = '1.0.0'
            CodeCoverageThreshold = 0.9
            IsAdministrator       = TestAdministrator
            Repository            = [PSCustomObject]@{
                Branch                = GetBranchName
                LastCommitMessage     = GetLastCommitMessage
            }
            Path                  = [PSCustomObject]@{
                ProjectRoot           = $projectRoot = GetProjectRoot
                Source                = GetSourcePath $projectRoot
                SourceManifest        = ''
                Package               = ''
                Output                = $output = [System.IO.DirectoryInfo](Join-Path $projectRoot 'output')
                Nuget                 = Join-Path $output 'packages'
                Manifest              = ''
                RootModule            = ''
            }
        } | Add-Member -TypeName 'BuildInfo' -PassThru

        $buildInfo.ModuleName = $buildInfo.Path.Source.Parent.GetDirectories($buildInfo.Path.Source.Name).Name
        $buildInfo.Path.SourceManifest = Join-Path $buildInfo.Path.Source ('{0}.psd1' -f $buildInfo.ModuleName)

        # Override the release type based on commit message if not explicitly defined.
        if (-not $psboundparameters.ContainsKey('ReleaseType')) {
            if ($buildInfo.Repository.LastCommitMessage -like '*major release*') {
                $ReleaseType = $buildInfo.ReleaseType = 'Major'
            } elseif ($buildInfo.Repository.LastCommitMessage -like '*release*') {
                $ReleaseType = $buildInfo.ReleaseType = 'Minor'
            }
        }
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
    } catch {
        $pscmdlet.ThrowTerminatingError($_)
    } finally {
        Pop-Location
    }
}