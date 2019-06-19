function Get-MethodInfo {
    <#
    .SYNOPSIS
        Get information about a method implemented in PowerShell class.
    .DESCRIPTION
        Get information about a method implemented in PowerShell class.
    .EXAMPLE
        Get-ChildItem -Filter *.psm1 | Get-MethodInfo

        Get all methods declared within all classes in the *.psm1 file.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromPath')]
    [OutputType('Indented.MemberInfo')]
    param (
        # The path to a file containing one or more functions.
        [Parameter(Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'FromPath')]
        [Alias('FullName')]
        [String]$Path,

        # A script block containing one or more functions.
        [Parameter(ParameterSetName = 'FromScriptBlock')]
        [ScriptBlock]$ScriptBlock
    )

    process {
        try {
            $ast = Get-Ast @psboundparameters

            $ast.FindAll(
                {
                    param( $childAst )

                    $childAst -is [System.Management.Automation.Language.FunctionMemberAst]
                },
                $IncludeNested
            ) | ForEach-Object {
                $ast = $_

                [PSCustomObject]@{
                    Name       = $ast.Name
                    FullName   = '{0}\{1}' -f $_.Parent.Name, $_.Name
                    Extent     = $ast.Extent | Select-Object File, StartLineNumber, EndLineNumber
                    Definition = $ast.Extent.ToString()
                    PSTypeName = 'Indented.MemberInfo'
                }
            }
        } catch {
            Write-Error -ErrorRecord $_
        }
    }
}