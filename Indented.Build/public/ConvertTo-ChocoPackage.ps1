function ConvertTo-ChocoPackage {
    <#
    .SYNOPSIS
        Convert a PowerShell module into a chocolatey package.
    .DESCRIPTION
        Convert a PowerShell module into a chocolatey package.
    .EXAMPLE
        Find-Module pester | ConvertTo-ChocoPackage

        Find the module pester on a PS repository and convert the module to a chocolatey package.
    .EXAMPLE
        Get-Module SqlServer -ListAvailable | ConvertTo-ChocoPackage

        Get the installed module SqlServer and convert the module to a chocolatey package.
    .EXAMPLE
        Find-Module VMware.PowerCli | ConvertTo-ChocoPackage

        Find the module VMware.PowerCli on a PS repository and convert the module, and all dependencies, to chocolatey packages.
    #>

    [CmdletBinding()]
    param (
        # The module to package.
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript( {
            if ($_ -is [System.Management.Automation.PSModuleInfo] -or
                $_ -is [Microsoft.PackageManagement.Packaging.SoftwareIdentity] -or
                $_.PSTypeNames[0] -eq 'Microsoft.PowerShell.Commands.PSRepositoryItemInfo') {


                $true
            } else {
                throw 'InputObject must be a PSModuleInfo, SoftwareIdentity, or PSRepositoryItemInfo object.'
            }
        } )]
        [Object]$InputObject,

        # Write the generated nupkg file to the specified folder.
        [String]$Path = '.',

        # A temporary directory used to stage the choco package content before packing.
        [String]$CacheDirectory = (Join-Path $env:TEMP (New-Guid))
    )

    begin {
        $Path = $pscmdlet.GetUnresolvedProviderPathFromPSPath($Path)

        try {
            $null = New-Item $CacheDirectory -ItemType Directory
        } catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        try {
            $erroractionpreference = 'Stop'

            $packagePath = Join-Path $CacheDirectory $InputObject.Name.ToLower()
            $toolsPath = New-Item (Join-Path $packagePath 'tools') -ItemType Directory

            switch ($InputObject) {
                { $_ -is [System.Management.Automation.PSModuleInfo] } {
                    Write-Verbose ('Building {0} from PSModuleInfo' -f $InputObject.Name)

                    $dependencies = $InputObject.RequiredModules

                    $null = $psboundparameters.Remove('InputObject')
                    # Package dependencies as well
                    foreach ($dependency in $dependencies) {
                        Get-Module $dependency.Name -ListAvailable |
                            Where-Object Version -eq $dependency.Version |
                            ConvertTo-ChocoPackage @psboundparameters
                    }

                    if ((Split-Path $InputObject.ModuleBase -Leaf) -eq $InputObject.Version) {
                        $destination = New-Item (Join-Path $toolsPath $InputObject.Name) -ItemType Directory
                    } else {
                        $destination = $toolsPath
                    }

                    Copy-Item $InputObject.ModuleBase -Destination $destination -Recurse

                    break
                }
                { $_ -is [Microsoft.PackageManagement.Packaging.SoftwareIdentity] } {
                    Write-Verbose ('Building {0} from SoftwareIdentity' -f $InputObject.Name)

                    $dependencies = $InputObject.Dependencies |
                        Select-Object @{n='Name';e={ $_ -replace 'powershellget:|/.+$' }},
                                      @{n='Version';e={ $_ -replace '^.+?/|#.+$' }}

                    [Xml]$swidTagText = $InputObject.SwidTagText

                    $InputObject = [PSCustomObject]@{
                        Name        = $InputObject.Name
                        Version     = $InputObject.Version
                        Author      = $InputObject.Entities.Where{ $_.Role -eq 'author' }.Name
                        Copyright   = $swidTagText.SoftwareIdentity.Meta.copyright
                        Description = $swidTagText.SoftwareIdentity.Meta.summary
                    }

                    if ((Split-Path $swidTagText.SoftwareIdentity.Meta.InstalledLocation -Leaf) -eq $InputObject.Version) {
                        $destination = New-Item (Join-Path $toolsPath $InputObject.Name) -ItemType Directory
                    } else {
                        $destination = $toolsPath
                    }

                    Copy-Item $swidTagText.SoftwareIdentity.Meta.InstalledLocation -Destination $destination -Recurse

                    break
                }
                { $_.PSTypeNames[0] -eq 'Microsoft.PowerShell.Commands.PSRepositoryItemInfo' } {
                    Write-Verbose ('Building {0} from PSRepositoryItemInfo' -f $InputObject.Name)

                    $dependencies = $InputObject.Dependencies |
                        Select-Object @{n='Name';e={ $_['Name'] }}, @{n='Version';e={ $_['MinimumVersion'] }}

                    $null = $psboundparameters.Remove('InputObject')
                    $params = @{
                        Name            = $InputObject.Name
                        RequiredVersion = $InputObject.Version
                        Source          = $InputObject.Repository
                        ProviderName    = 'PowerShellGet'
                        Path            = New-Item (Join-Path $CacheDirectory 'savedPackages') -ItemType Directory -Force
                    }
                    Save-Package @params | ConvertTo-ChocoPackage @psboundparameters

                    # The current module will be last in the chain. Prevent packaging of this iteration.
                    $InputObject = $null

                    break
                }
            }

            if ($InputObject) {
                # Inject chocolateyInstall.ps1
                $install = @(
                    'Get-ChildItem $psscriptroot -Directory |'
                    '    Copy-Item -Destination "C:\Program Files\WindowsPowerShell\Modules" -Recurse -Force'
                ) | Out-String
                Set-Content (Join-Path $toolsPath 'chocolateyInstall.ps1') -Value $install

                # Inject chocolateyUninstall.ps1
                $uninstall = @(
                    'Get-Module {0} -ListAvailable |'
                    '    Where-Object {{ $_.Version -eq "{1}" -and $_.ModuleBase -match "Program Files\\WindowsPowerShell\\Modules" }} |'
                    '    Select-Object -ExpandProperty ModuleBase |'
                    '    Remove-Item -Recurse -Force'
                ) | Out-String
                $uninstall = $uninstall -f $InputObject.Name,
                                           $InputObject.Version
                Set-Content (Join-Path $toolsPath 'chocolateyUninstall.ps1') -Value $uninstall

                # Inject nuspec
                $nuspecPath = Join-Path $packagePath ('{0}.nuspec' -f $InputObject.Name)
                $nuspec = @(
                    '<?xml version="1.0" encoding="utf-8"?>'
                    '<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">'
                    '    <metadata>'
                    '        <version>{0}</version>'
                    '        <title>{1}</title>'
                    '        <authors>{2}</authors>'
                    '        <copyright>{3}</copyright>'
                    '        <id>{1}</id>'
                    '        <summary>{1} PowerShell module</summary>'
                    '        <description>{4}</description>'
                    '    </metadata>'
                    '</package>'
                ) | Out-String
                $nuspec = [Xml]($nuspec -f @(
                    $InputObject.Version,
                    $InputObject.Name,
                    $InputObject.Author,
                    $InputObject.Copyright,
                    $InputObject.Description
                ))
                if ($dependencies) {
                    $fragment = [System.Text.StringBuilder]::new('<dependencies>')

                    $null = foreach ($dependency in $dependencies) {
                        $fragment.AppendFormat('<dependency id="{0}"', $dependency.Name)
                        if ($dependency.Version) {
                            $fragment.AppendFormat(' version="{0}"', $dependency.Version)
                        }
                        $fragment.Append(' />').AppendLine()
                    }

                    $null = $fragment.AppendLine('</dependencies>')

                    $xmlFragment = $nuspec.CreateDocumentFragment()
                    $xmlFragment.InnerXml = $fragment.ToString()

                    $null = $nuspec.package.metadata.AppendChild($xmlFragment)
                }
                $nuspec.Save($nuspecPath)

                choco pack $nuspecPath --out=$Path
            }
        } catch {
            Write-Error -ErrorRecord $_
        } finally {
            Remove-Item $packagePath -Recurse -Force
        }
    }

    end {
        Remove-Item $CacheDirectory -Recurse -Force
    }
}