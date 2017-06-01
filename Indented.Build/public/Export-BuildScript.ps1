function Export-BuildScript {
    <#
    .SYNOPSIS
        Export a persistent build script.
    .DESCRIPTION
        Export a persistent build script (as .build.ps1).
    .INPUTS
        BuildInfo (from Get-BuildInfo)
    #>

    [CmdletBinding()]
    [OutputType([Void])]
    param (
        # The build information object is used to determine which tasks are applicable.
        [Parameter(ValueFromPipeline = $true)]
        [PSTypeName('BuildInfo')]
        [PSObject]$BuildInfo = (Get-BuildInfo),

        # By default the build system is automatically discovered. The BuildSystem parameter overrides any automatically discovered value. Tasks associated with the build system are added to the generated script.
        [String]$BuildSystem
    )

    if ($BuildSystem) {
        $BuildInfo.BuildSystem = $BuildSystem
    }

    $script = New-Object System.Text.StringBuilder 
    # Add supporting functions to create the BuildInfo object.
    (Get-Command Get-BuildInfo).ScriptBlock.Ast.FindAll( {
            param ( $ast )

            $ast -is [Management.Automation.Language.CommandAst]
        },
        $true
    ) | ForEach-Object GetCommandName |
        Select-Object -Unique |
        Sort-Object |
        ForEach-Object {
            $commandInfo = Get-Command $_

            if ($commandInfo.Source -eq $myinvocation.MyCommand.ModuleName) {
                $null = $script.AppendFormat('function {0} {{', $commandInfo.Name).
                                Append($commandInfo.Definition).
                                AppendLine('}').
                                AppendLine()
            }
        }
    
    'Enable-Metadata', 'Get-BuildInfo', 'Get-BuildItem' | ForEach-Object { 
        $null = $script.AppendFormat('function {0} ', $_).
                        AppendLine('{').
                        Append((Get-Command $_).Definition).
                        AppendLine('}').
                        AppendLine()
    }

    $tasks = $BuildInfo | Get-BuildTask | Sort-Object {
        switch ($_.Stage) {
            'Setup'   { 1 }
            'Build'   { 2 }
            'Test'    { 3 }
            'Publish' { 4 }
        }
    }, Order, Name

    # Build the wrapper tasks
    $tasks | Group-Object Stage | ForEach-Object {
        $indentLength = 'task '.Length + $_.Name.Length
        $null = $script.AppendFormat('task {0} {1}', $_.Name, $_.Group[0].Name)
        foreach ($task in $_.Group | Select-Object -Skip 1) {
            $null = $script.Append(',').
                            AppendLine().
                            AppendFormat('{0} {1}', (' ' * $indentLength), $task.Name)
        }
        $null = $script.AppendLine().
                        AppendLine()
    }

    $tasks | ForEach-Object {
        $null = $script.AppendFormat('task {0}', $_.Name)
        if ($_.If -and $_.If.ToString().Trim() -ne '$true') {
            $null = $script.AppendFormat(' -If ({0})', $_.If.ToString().Trim())
        }
        $null = $script.AppendLine(' {').
                        AppendLine($_.Definition.ToString().Trim("`r`n")).
                        AppendLine('}').
                        AppendLine()
    }

    $script.ToString()
}