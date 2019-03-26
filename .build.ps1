param (
    [String]$ModuleName,

    [PSTypeName("Indented.BuildInfo")]
    [ValidateCount(1, 1)]
    [PSObject[]]$BuildInfo
)

task default Setup,
             Build,
             Test,
             Pack

task Setup SetBuildInfo,
           InstallRequiredModules

task Build Clean,
           TestSyntax,
           TestAttributeSyntax,
           CopyModuleFiles,
           Merge,
           UpdateMetadata,
           UpdateMarkdownHelp

task Test TestModuleImport,
          PSScriptAnalyzer,
          TestModule,
          AddAppveyorCommitMessage,
          UploadAppVeyorTestResults,
          ValidateTestResults,
          CreateCodeHealthReport

task Pack CreateChocoPackage

task Publish PublishToCurrentUser,
             PublishToPSGallery

function GetBuildSystem {
    [OutputType([String])]
    param ( )

    if ($env:APPVEYOR -eq $true) { return 'AppVeyor' }
    if ($env:JENKINS_URL)        { return 'Jenkins' }

    return 'Desktop'
}

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

function Enable-Metadata {
    <#
    .SYNOPSIS
        Enable a metadata property which has been commented out.
    .DESCRIPTION
        This function is derived Get and Update-Metadata from PoshCode\Configuration.

        A boolean value is returned indicating if the property is available in the metadata file.

        If the property does not exist, or exists more than once within the specified file this command will return false.
    .INPUTS
        System.String
    .EXAMPLE
        Enable-Metadata .\module.psd1 -PropertyName RequiredAssemblies

        Enable an existing (commented) RequiredAssemblies property within the module.psd1 file.
    #>

    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        # A valid metadata file or string containing the metadata.
        [Parameter(ValueFromPipelineByPropertyName, Position = 0)]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [Alias("PSPath")]
        [String]$Path,

        # The property to enable.
        [String]$PropertyName
    )

    process {
        # If the element can be found using Get-Metadata leave it alone and return true
        $shouldEnable = $false
        try {
            $null = Get-Metadata @psboundparameters -ErrorAction Stop
        } catch [System.Management.Automation.ItemNotFoundException] {
            # The function will only execute where the requested value is not present
            $shouldEnable = $true
        } catch {
            # Ignore other errors which may be raised by Get-Metadata except path not found.
            if ($_.Exception.Message -eq 'Path must point to a .psd1 file') {
                $pscmdlet.ThrowTerminatingError($_)
            }
        }
        if (-not $shouldEnable) {
            return $true
        }

        $manifestContent = Get-Content $Path -Raw

        $tokens = $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            $manifestContent,
            $Path,
            [Ref]$tokens,
            [Ref]$parseErrors
        )

        # Attempt to find a comment which matches the requested property
        $regex = '^ *# *({0}) *=' -f $PropertyName
        $existingValue = @($tokens | Where-Object { $_.Kind -eq 'Comment' -and $_.Text -match $regex })
        if ($existingValue.Count -eq 1) {
            $manifestContent = $ast.Extent.Text.Remove(
                $existingValue.Extent.StartOffset,
                $existingValue.Extent.EndOffset - $existingValue.Extent.StartOffset
            ).Insert(
                $existingValue.Extent.StartOffset,
                $existingValue.Extent.Text -replace '^# *'
            )

            try {
                Set-Content -Path $Path -Value $manifestContent -NoNewline -ErrorAction Stop
                $true
            } catch {
                $false
            }
        } elseif ($existingValue.Count -eq 0) {
            # Item not found
            Write-Warning "Cannot find disabled property '$PropertyName' in $Path"
            $false
        } else {
            # Ambiguous match
            Write-Warning "Found more than one '$PropertyName' in $Path"
            $false
        }
    }
}

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

function Get-FunctionInfo {
    <#
    .SYNOPSIS
        Get an instance of FunctionInfo.
    .DESCRIPTION
        FunctionInfo does not present a public constructor. This function calls an internal / private constructor on FunctionInfo to create a description of a function from a script block or file containing one or more functions.
    .EXAMPLE
        Get-ChildItem -Filter *.psm1 | Get-FunctionInfo

        Get all functions declared within the *.psm1 file and construct FunctionInfo.
    .EXAMPLE
        Get-ChildItem C:\Scripts -Filter *.ps1 -Recurse | Get-FunctionInfo

        Get all functions declared in all ps1 files in C:\Scripts.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromPath')]
    [OutputType([System.Management.Automation.FunctionInfo])]
    param (
        # The path to a file containing one or more functions.
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'FromPath')]
        [Alias('FullName')]
        [String]$Path,

        # A script block containing one or more functions.
        [Parameter(ParameterSetName = 'FromScriptBlock')]
        [ScriptBlock]$ScriptBlock,

        # By default functions nested inside other functions are ignored. Setting this parameter will allow nested functions to be discovered.
        [Switch]$IncludeNested
    )

    begin {
        $executionContextType = [PowerShell].Assembly.GetType('System.Management.Automation.ExecutionContext')
        $constructor = [System.Management.Automation.FunctionInfo].GetConstructor(
            [System.Reflection.BindingFlags]'NonPublic, Instance',
            $null,
            [System.Reflection.CallingConventions]'Standard, HasThis',
            ([String], [ScriptBlock], $executionContextType),
            $null
        )
    }

    process {
        if ($pscmdlet.ParameterSetName -eq 'FromPath') {
            try {
                $scriptBlock = [ScriptBlock]::Create((Get-Content $Path -Raw))
            } catch {
                $ErrorRecord = @{
                    Exception = $_.Exception.InnerException
                    ErrorId   = 'InvalidScriptBlock'
                    Category  = 'OperationStopped'
                }
                Write-Error @ErrorRecord
            }
        }

        if ($scriptBlock) {
            $scriptBlock.Ast.FindAll( {
                    param( $ast )

                    $ast -is [System.Management.Automation.Language.FunctionDefinitionAst]
                },
                $IncludeNested
            ) | ForEach-Object {
                try {
                    $internalScriptBlock = $_.Body.GetScriptBlock()
                } catch {
                    Write-Debug $_.Exception.Message
                }
                if ($internalScriptBlock) {
                    $constructor.Invoke(([String]$_.Name, $internalScriptBlock, $null))
                }
            }
        }
    }
}

task GetBuildInfo {
    Get-BuildInfo
}

task BuildAll {
    [String[]]$task = ${*}.Task.Name

    # Re-submit the build request without the BuildAll task
    if ($task.Count -eq 1 -and $task[0] -eq "BuildAll") {
        $task = "default"
    } else {
        $task = $task -ne "BuildAll"
    }

    Get-BuildInfo | ForEach-Object {
        Write-Host
        "Building {0} ({1})" -f $_.ModuleName, $_.Version | Write-Host -ForegroundColor Green
        Write-Host
        Invoke-Build -BuildInfo $_ -Task $task
    }
}

task SetBuildInfo -If (-not $Script:BuildInfo) {
    $params = @{}
    if ($Script:moduleName) {
        $params.Add('ModuleName', $Script:moduleName)
    }
    $Script:BuildInfo = Get-BuildInfo @params

    if (@($Script:BuildInfo).Count -gt 1) {
        throw 'Either a unique module name must be supplied or the BuildAll task must be used to build all modules.'
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
            Remove-Item $buildInfo.Path.Build.Parent.FullName -Recurse -Force
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

task TestSyntax {
    $hasSyntaxErrors = $false

    $buildInfo | Get-BuildItem -Type ShouldMerge -ExcludeClass | ForEach-Object {
        $tokens = $null
        [System.Management.Automation.Language.ParseError[]]$parseErrors = @()
        $null = [System.Management.Automation.Language.Parser]::ParseInput(
            (Get-Content $_.FullName -Raw),
            $_.FullName,
            [Ref]$tokens,
            [Ref]$parseErrors
        )

        if ($parseErrors.Count -gt 0) {
            $parseErrors | Write-Error

            $hasSyntaxErrors = $true
        }
    }

    if ($hasSyntaxErrors) {
        throw 'TestSyntax failed'
    }
}

task TestAttributeSyntax {
    $hasSyntaxErrors = $false
    $buildInfo | Get-BuildItem -Type ShouldMerge -ExcludeClass | ForEach-Object {
        $tokens = $null
        [System.Management.Automation.Language.ParseError[]]$parseErrors = @()
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            (Get-Content $_.FullName -Raw),
            $_.FullName,
            [Ref]$tokens,
            [Ref]$parseErrors
        )

        # Test attribute syntax
        $attributes = $ast.FindAll(
            { $args[0] -is [System.Management.Automation.Language.AttributeAst] },
            $true
        )
        foreach ($attribute in $attributes) {
            if (($type = $attribute.TypeName.FullName -as [Type]) -or ($type = ('{0}Attribute' -f $attribute.TypeName.FullName) -as [Type])) {
                $propertyNames = $type.GetProperties().Name

                if ($attribute.NamedArguments.Count -gt 0) {
                    foreach ($argument in $attribute.NamedArguments) {
                        if ($argument.ArgumentName -notin $propertyNames) {
                            'Invalid property name in attribute declaration: {0}: {1} at line {2}, character {3}' -f
                                $_.Name,
                                $argument.ArgumentName,
                                $argument.Extent.StartLineNumber,
                                $argument.Extent.StartColumnNumber

                            $hasSyntaxErrors = $true
                        }
                    }
                }
            } else {
                'Invalid attribute declaration: {0}: {1} at line {2}, character {3}' -f
                    $_.Name,
                    $attribute.TypeName.FullName,
                    $attribute.Extent.StartLineNumber,
                    $attribute.Extent.StartColumnNumber

                $hasSyntaxErrors = $true
            }
        }
    }

    if ($hasSyntaxErrors) {
        throw 'TestAttributeSyntax failed'
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

        # DscResourcesToExport
        $tokens = $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $buildInfo.Path.Build.RootModule,
            [Ref]$tokens,
            [Ref]$parseErrors
        )
        $dscResourcesToExport = $ast.FindAll( {
            param ($ast)

            $ast -is [System.Management.Automation.Language.TypeDefinitionAst] -and
            $ast.IsClass -and
            $ast.Attributes.TypeName.FullName -contains 'DscResource'
        }, $true).Name
        if ($null -ne $dscResourcesToExport) {
            if (Enable-Metadata $path -PropertyName DscResourcesToExport) {
                Update-Metadata $path -PropertyName DscResourcesToExport -Value $dscResourcesToExport
            }
        }

        # RequiredAssemblies
        if (Test-Path (Join-Path $buildInfo.Path.Build.Module 'lib\*.dll')) {
            if (Enable-Metadata $path -PropertyName RequiredAssemblies) {
                Update-Metadata $path -PropertyName RequiredAssemblies -Value (
                    (Get-Item (Join-Path $buildInfo.Path.Package 'lib\*.dll')).Name | ForEach-Object {
                        Join-Path 'lib' $_
                    }
                )
            }
        }

        # FormatsToProcess
        if (Test-Path (Join-Path $buildInfo.Path.Build.Module '*.Format.ps1xml')) {
            if (Enable-Metadata $path -PropertyName FormatsToProcess) {
                Update-Metadata $path -PropertyName FormatsToProcess -Value (Get-Item (Join-Path $buildInfo.Path.Build.Module '*.Format.ps1xml')).Name
            }
        }

        # LicenseUri
        if ($build.Config.License -and $buildInfo.Config.License -ne 'None') {
            if (Enable-Metadata $path -PropertyName LicenseUri) {
                Update-Metadata $path -PropertyName LicenseUri -Value ('https://opensource.org/licenses/{0}' -f @(
                    $buildInfo.Config.License
                ))
            }
        }
    } catch {
        throw
    }
}

task UpdateMarkdownHelp -If (Get-Module platyPS -ListAvailable) {
    Start-Job -ArgumentList $buildInfo -ScriptBlock {
        param (
            $buildInfo
        )

        $path = Join-Path $buildInfo.Path.Source.Module 'test*'

        if (Test-Path (Join-Path $path 'stub')) {
            Get-ChildItem (Join-Path $path 'stub') -Filter *.psm1 -Recurse -Depth 1 | ForEach-Object {
                Import-Module $_.FullName -Global -WarningAction SilentlyContinue
            }
        }

        try {
            $moduleInfo = Import-Module $buildInfo.Path.Build.Manifest.FullName -ErrorAction Stop -PassThru
            if ($moduleInfo.ExportedCommands.Count -gt 0) {
                New-MarkdownHelp -Module $buildInfo.ModuleName -OutputFolder (Join-Path $buildInfo.Path.Source.Module 'help') -Force
            }
        } catch {
            throw
        }
    } | Receive-Job -Wait -ErrorAction Stop
}

task TestModuleImport {
    $script = {
        param (
            $buildInfo
        )

        $path = Join-Path $buildInfo.Path.Source.Module 'test*'

        if (Test-Path (Join-Path $path 'stub')) {
            Get-ChildItem (Join-Path $path 'stub') -Filter *.psm1 -Recurse -Depth 1 | ForEach-Object {
                Import-Module $_.FullName -Global -WarningAction SilentlyContinue
            }
        }

        Import-Module $buildInfo.Path.Build.Manifest.FullName -ErrorAction Stop
    }

    if ($buildInfo.BuildSystem -eq 'Desktop') {
        Start-Job -ArgumentList $buildInfo -ScriptBlock $script | Receive-Job -Wait -ErrorAction Stop
    } else {
        & $script -BuildInfo $buildInfo
    }
}

task PSScriptAnalyzer -If (Get-Module PSScriptAnalyzer -ListAvailable) {
    try {
        Push-Location $buildInfo.Path.Source.Module
        'priv*', 'pub*', 'InitializeModule.ps1' | Where-Object { Test-Path $_ } | ForEach-Object {
            $path = Resolve-Path (Join-Path $buildInfo.Path.Source.Module $_)
            if (Test-Path $path) {
                Invoke-ScriptAnalyzer -Path $path -Recurse | ForEach-Object {
                    $_
                    $_ | Export-Csv (Join-Path $buildInfo.Path.Build.Output 'psscriptanalyzer.csv') -NoTypeInformation -Append
                }
            }
        }
    } catch {
        throw
    } finally {
        Pop-Location
    }
}

task TestModule {
    if (-not (Get-ChildItem (Resolve-Path (Join-Path $buildInfo.Path.Source.Module 'test*')).Path -Filter *.tests.ps1 -Recurse -File)) {
        throw 'The PS project must have tests!'
    }

    $script = {
        param (
            $buildInfo
        )

        $path = Join-Path $buildInfo.Path.Source.Module 'test*'

        if (Test-Path (Join-Path $path 'stub')) {
            Get-ChildItem (Join-Path $path 'stub') -Filter *.psm1 -Recurse -Depth 1 | ForEach-Object {
                Import-Module $_.FullName -Global -WarningAction SilentlyContinue
            }
        }

        Import-Module $buildInfo.Path.Build.Manifest -Global -ErrorAction Stop
        $params = @{
            Script       = $path
            CodeCoverage = $buildInfo.Path.Build.RootModule
            OutputFile   = Join-Path $buildInfo.Path.Build.Output ('{0}-nunit.xml' -f $buildInfo.ModuleName)
            PassThru     = $true
        }
        Invoke-Pester @params
    }

    if ($buildInfo.BuildSystem -eq 'Desktop') {
        $pester = Start-Job -ArgumentList $buildInfo -ScriptBlock $script | Receive-Job -Wait
    } else {
        $pester = & $script -BuildInfo $buildInfo
    }

    $path = Join-Path $buildInfo.Path.Build.Output 'pester-output.xml'
    $pester | Export-CliXml $path
}

task AddAppveyorCommitMessage -If ($buildInfo.BuildSystem -eq 'AppVeyor') {
    $path = Join-Path $buildInfo.Path.Build.Output 'pester-output.xml'
    if (Test-Path $path) {
        $pester = Import-CliXml $path

        $params = @{
            Message  = 'Passed {0} of {1} tests' -f @(
                $pester.PassedCount
                $pester.TotalCount
            )
            Category = 'Information'
        }
        if ($pester.FailedCount -gt 0) {
            $params.Category = 'Warning'
        }
        Add-AppVeyorCompilationMessage @params

        if ($pester.CodeCoverage) {
            [Double]$codeCoverage = $pester.Config.CodeCoverage.NumberOfCommandsExecuted / $pester.Config.CodeCoverage.NumberOfCommandsAnalyzed

            $params = @{
                Message  = '{0:P2} test coverage' -f $codeCoverage
                Category = 'Information'
            }
            if ($codecoverage -lt $buildInfo.Config.CodeCoverageThreshold) {
                $params.Category = 'Warning'
            }
            Add-AppVeyorCompilationMessage @params
        }
    }

    # Solution
    Get-ChildItem $buildInfo.Path.Build.Output -Filter *.dll.xml | ForEach-Object {
        $report = [Xml](Get-Content $_.FullName -Raw)
        $params = @{
            Message = 'Passed {0} of {1} solution tests in {2}' -f @(
                $report.'test-run'.passed
                $report.'test-run'.total
                $report.'test-run'.'test-suite'.name
            )
            Category = 'Information'
        }
        if ([Int]$report.'test-run'.failed -gt 0) {
            $params.Category = 'Warning'
        }
        Add-AppVeyorCompilationMessage @params
    }
}

task UploadAppVeyorTestResults -If ($buildInfo.BuildSystem -eq 'AppVeyor') {
    $path = Join-Path $buildInfo.Path.Build.Output ('{0}.xml' -f $buildInfo.ModuleName)
    if (Test-Path $path) {
        [System.Net.WebClient]::new().UploadFile(('https://ci.appveyor.com/api/testresults/nunit/{0}' -f $env:APPVEYOR_JOB_ID), $path)
    }
}

task ValidateTestResults {
    $testsFailed = $false

    $path = Join-Path $buildInfo.Path.Build.Output 'pester-output.xml'
    $pester  = Import-CliXml $path

    # PSScriptAnalyzer
    $path = Join-Path $buildInfo.Path.Build.Output 'psscriptanalyzer.csv'
    if ((Test-Path $path) -and ($testResults = Import-Csv $path)) {
        '{0} warnings were raised by PSScriptAnalyzer' -f @($testResults).Count
        $testsFailed = $true
    }

    # Pester tests
    if ($pester.FailedCount -gt 0) {
        '{0} of {1} pester tests are failing' -f $pester.FailedCount, $pester.TotalCount
        $testsFailed = $true
    }

    # Pester code coverage
    [Double]$codeCoverage = $pester.CodeCoverage.NumberOfCommandsExecuted / $pester.CodeCoverage.NumberOfCommandsAnalyzed
    $pester.CodeCoverage.MissedCommands | Export-Csv (Join-Path $buildInfo.Path.Build.Output 'CodeCoverage.csv') -NoTypeInformation

    if ($codecoverage -lt $buildInfo.Config.CodeCoverageThreshold) {
        'Pester code coverage ({0:P}) is below threshold {1:P}.' -f @(
            $codeCoverage
            $buildInfo.Config.CodeCoverageThreshold
        )
        $testsFailed = $true
    }

    # Solution tests
    Get-ChildItem $buildInfo.Path.Build.Output -Filter *.dll.xml | ForEach-Object {
        $report = [Xml](Get-Content $_.FullName -Raw)
        if ([Int]$report.'test-run'.failed -gt 0) {
            '{0} of {1} solution tests in {2} are failing' -f @(
                $report.'test-run'.failed
                $report.'test-run'.total
                $report.'test-run'.'test-suite'.name
            )
            $testsFailed = $true
        }
    }

    if ($testsFailed) {
        throw 'Test result validation failed'
    }
}

task CreateCodeHealthReport -If (Get-Module PSCodeHealth -ListAvailable) {
     $script = {
        param (
            $buildInfo
        )

        $path = Join-Path $buildInfo.Path.Source.Module 'test*'

        if (Test-Path (Join-Path $path 'stub')) {
            Get-ChildItem (Join-Path $path 'stub') -Filter *.psm1 -Recurse -Depth 1 | ForEach-Object {
                Import-Module $_.FullName -Global -WarningAction SilentlyContinue
            }
        }

        Import-Module $buildInfo.Path.Build.Manifest -Global -ErrorAction Stop
        $params = @{
            Path           = $buildInfo.Path.Build.RootModule
            Recurse        = $true
            TestsPath      = $path
            HtmlReportPath = Join-Path $buildInfo.Path.Build.Output ('{0}-code-health.html' -f $buildInfo.ModuleName)
        }
        Invoke-PSCodeHealth @params
    }

    if ($buildInfo.BuildSystem -eq 'Desktop') {
        Start-Job -ArgumentList $buildInfo -ScriptBlock $script | Receive-Job -Wait
    } else {
        & $script -BuildInfo $buildInfo
    }
}

task CreateChocoPackage -If (Get-Command choco -ErrorAction SilentlyContinue) {
    $script = {
        param (
            $buildInfo
        )

        Import-Module $buildInfo.Path.Build.Manifest

        Get-Module $buildInfo.ModuleName | ConvertTo-ChocoPackage -Path $buildInfo.Path.Build.Package
    }


    if ($buildInfo.BuildSystem -eq 'Desktop') {
        Start-Job -ArgumentList $buildInfo -ScriptBlock $script | Receive-Job -Wait
    } else {
        & $script -BuildInfo $buildInfo
    }
}

task PublishToCurrentUser {
    $path = '{0}\Documents\WindowsPowerShell\Modules\{1}' -f $home, $buildInfo.ModuleName
    if (-not (Test-Path $path)) {
        $null = New-Item $path -ItemType Directory
    }
    Copy-Item $buildInfo.Path.Build.Module -Destination $path -Recurse -Force
}

task PublishToPSGallery -If ($env:NuGetApiKey) {
    Publish-Module -Path $buildInfo.Path.Build.Module -NuGetApiKey $env:NuGetApiKey -Repository PSGallery -ErrorAction Stop
}


