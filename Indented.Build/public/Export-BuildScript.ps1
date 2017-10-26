using namespace System.Text

function Export-BuildScript {
    <#
    .SYNOPSIS
        Export a build script for use with Invoke-Build.
    .DESCRIPTION
        Export a build script for use with Invoke-Build.
    .INPUTS
        BuildInfo (from Get-BuildInfo)
    #>

    [CmdletBinding()]
    [OutputType([String])]
    param (
        # The build information object is used to determine which tasks are applicable.
        [Parameter(ValueFromPipeline = $true)]
        [PSTypeName('BuildInfo')]
        [PSObject]$BuildInfo = (Get-BuildInfo),

        # By default the build system is automatically discovered. The BuildSystem parameter overrides any automatically discovered value. Tasks associated with the build system are added to the generated script.
        [String]$BuildSystem,

        # If specified, the build script will be written to the the specified path. By default the build script is written (as a string) to the console.
        [String]$Path
    )

    if ($BuildSystem) {
        $BuildInfo.BuildSystem = $BuildSystem
    }

    $script = New-Object StringBuilder 

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
            'Setup'   { 1; break }
            'Build'   { 2; break }
            'Test'    { 3; break }
            'Pack'    { 4; break }
            'Publish' { 5; break }
        }
    }, Order, Name

    # Fill BuildInfo
    $null = $script.AppendLine('$buildInfo = Get-BuildInfo')

    # Build the wrapper tasks and insert the block at the top of the script
    $taskSets = New-Object StringBuilder
    # Add a default task set
    $null = $taskSets.AppendLine('task default Setup,').
                      AppendLine('             Build,').
                      AppendLine('             Test').
                      AppendLine()

    $tasks | Group-Object Stage | ForEach-Object {
        $indentLength = 'task '.Length + $_.Name.Length
        $null = $taskSets.AppendFormat('task {0} {1}', $_.Name, $_.Group[0].Name)
        foreach ($task in $_.Group | Select-Object -Skip 1) {
            $null = $taskSets.Append(',').
                              AppendLine().
                              AppendFormat('{0} {1}', (' ' * $indentLength), $task.Name)
        }
        $null = $taskSets.AppendLine().
                          AppendLine()
    }
    $null = $script.Insert(0, $taskSets.ToString())

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

    if ($Path) {
        $script.ToString() | Set-Content $Path
    } else {
        $script.ToString()
    }
}