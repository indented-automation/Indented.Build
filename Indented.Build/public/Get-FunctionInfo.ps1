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
        if ($pscmdlet.ParameterSetName -eq 'FromPath') {
            $Path = $pscmdlet.GetUnresolvedProviderPathFromPSPath($Path)

            try {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                    $Path,
                    [Ref]$tokens,
                    [Ref]$errors
                )
            } catch {
                $errorRecord = @{
                    Exception = $_.Exception.GetBaseException()
                    ErrorId   = 'AstParserFailed'
                    Category  = 'OperationStopped'
                }
                Write-Error @ErrorRecord
            }
        } else {
            $ast = $ScriptBlock.Ast
        }

        $ast.FindAll( {
                param( $childAst )

                $childAst -is [System.Management.Automation.Language.FunctionDefinitionAst]
            },
            $IncludeNested
        ) | ForEach-Object {
            try {
                $internalScriptBlock = $_.Body.GetScriptBlock()
            } catch {
                Write-Debug $_.Exception.Message
            }
            if ($internalScriptBlock) {
                $extent = $_.Extent | Select-Object File, StartLineNumber, EndLineNumber

                $constructor.Invoke(([String]$_.Name, $internalScriptBlock, $null)) |
                    Add-Member -NotePropertyName Extent -NotePropertyValue $extent -PassThru
            }
        }
    }
}