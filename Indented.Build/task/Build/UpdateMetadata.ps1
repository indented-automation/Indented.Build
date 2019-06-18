BuildTask UpdateMetadata -Stage Build -Order 5 -Definition {
    # Update the psd1 document.

    try {
        $path = $buildInfo.Path.Build.Manifest.FullName

        # Version
        Update-Metadata $path -PropertyName ModuleVersion -Value $buildInfo.Version

        # RootModule
        if (Test-Path $buildInfo.Path.Build.RootModule) {
            if (Enable-Metadata $path -PropertyName RootModule) {
                Update-Metadata $path -PropertyName RootModule -Value $buildInfo.Path.Build.RootModule.Name
            }
        } else {
            $rootModule = $buildInfo.Path.Build.RootModule -replace '\.psm1$', '.dll'
            if (Test-Path $rootModule) {
                if (Enable-Metadata $path -PropertyName RootModule) {
                    Update-Metadata $path -PropertyName RootModule -Value (Split-Path $rootModule -Leaf)
                }
            }
        }

        # CmdletsToExport / AliasesToExport
        foreach ($directory in '', 'lib') {
            $assemblyPath = [System.IO.Path]::Combine(
                $buildInfo.Path.Build.Module,
                $directory,
                '{0}.dll' -f $buildInfo.ModuleName
            )

            if (Test-Path $assemblyPath) {
                $script = {
                    param ( $assemblyPath )

                    $moduleInfo = Import-Module $assemblyPath -ErrorAction SilentlyContinue -PassThru
                    [PSCustomObject]@{
                        Cmdlet = [String[]]$moduleInfo.ExportedCmdlets.Keys
                        Alias  = [String[]]$moduleInfo.ExportedAliases.Keys
                    }
                }
                if ($buildInfo.BuildSystem -eq 'Desktop') {
                    $moduleInfo = Start-Job -ScriptBlock $script -ArgumentList $assemblyPath | Receive-Job -Wait
                } else {
                    $moduleInfo = & $script -Path $assemblyPath
                }
                if ($moduleInfo.Cmdlet) {
                    if (Enable-Metadata $path -PropertyName CmdletsToExport) {
                        Update-Metadata $path -PropertyName CmdletsToExport -Value $moduleInfo.Cmdlet
                    }
                } else {
                    if (Get-Metadata $path -PropertyName CmdletsToExport -ErrorAction SilentlyContinue) {
                        Update-Metadata $path -PropertyName CmdletsToExport -Value @()
                    }
                }
                if ($moduleInfo.Alias) {
                    if (Enable-Metadata $path -PropertyName AliasesToExport) {
                        Update-Metadata $path -PropertyName AliasesToExport -Value $moduleInfo.Alias
                    }
                }
            }
        }

        # FunctionsToExport
        $functionsToExport = Get-ChildItem (Join-Path $buildInfo.Path.Source.Module 'pub*') -Filter '*.ps1' -Recurse |
            Get-FunctionInfo
        if ($functionsToExport) {
            if (Enable-Metadata $path -PropertyName FunctionsToExport) {
                Update-Metadata $path -PropertyName FunctionsToExport -Value $functionsToExport.Name
            }
        } else {
            if (Get-Metadata $path -PropertyName FunctionsToExport -ErrorAction SilentlyContinue) {
                Update-Metadata $path -PropertyName FunctionsToExport -Value @()
            }
        }

        # AliasesToExport
        if ($functionsToExport) {
            $aliasesToExport = foreach ($function in $functionsToExport) {
                $function.ScriptBlock.Ast.FindAll( {
                        param ( $ast )

                        $ast -is [System.Management.AUtomation.Language.AttributeAst] -and
                        $args[0].TypeName.Name -eq 'Alias'
                }, $false).PositionalArguments.Value
            }
            if ($aliasesToExport) {
                $aliasesToExport += @(Get-Metadata $path -PropertyName AliasesToExport -ErrorAction SilentlyContinue)

                if (Enable-Metadata $path -PropertyName AliasesToExport) {
                    Update-Metadata $path -PropertyName AliasesToExport -Value $aliasesToExport
                }
            }
        }
        if ((Get-Metadata $path -PropertyName AliasesToExport -ErrorAction SilentlyContinue) -eq '*') {
            Update-Metadata $path -PropertyName AliasesToExport -Value @()
        }

        # VariablesToExport
        if (Get-Metadata $path -PropertyName VariablesToExport -ErrorAction SilentlyContinue) {
            Update-Metadata $path -PropertyName VariablesToExport -Value @()
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
                    (Get-Item (Join-Path $buildInfo.Path.Build.Module 'lib\*.dll')).Name | ForEach-Object {
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