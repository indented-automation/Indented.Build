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
        [Parameter(Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'FromPath')]
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
        try {
            $ast = Get-Ast @psboundparameters

            $ast.FindAll(
                {
                    param( $childAst )

                    $childAst -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $childAst.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst]
                },
                $IncludeNested
            ) | ForEach-Object {
                $ast = $_

                try {
                    $internalScriptBlock = $ast.Body.GetScriptBlock()
                } catch {
                    Write-Debug ('{0} :: {1} : {2}' -f $path, $ast.Name, $_.Exception.Message)
                }
                if ($internalScriptBlock) {
                    $extent = $ast.Extent | Select-Object File, StartLineNumber, EndLineNumber

                    $constructor.Invoke(([String]$ast.Name, $internalScriptBlock, $null)) |
                        Add-Member -NotePropertyName Extent -NotePropertyValue $extent -PassThru
                }
            }
        } catch {
            Write-Error -ErrorRecord $_
        }
    }
}