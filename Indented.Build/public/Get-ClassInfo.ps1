function Get-ClassInfo {
    <#
    .SYNOPSIS
        Get information about a class implemented in PowerShell.
    .DESCRIPTION
        Get information about a class implemented in PowerShell.
    .EXAMPLE
        Get-ChildItem -Filter *.psm1 | Get-ClassInfo

        Get all classes declared within the *.psm1 file.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromPath')]
    [OutputType('Indented.ClassInfo')]
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

                    $childAst -is [System.Management.Automation.Language.TypeDefinitionAst]
                },
                $IncludeNested
            ) | ForEach-Object {
                $ast = $_

                [PSCustomObject]@{
                    Name       = $ast.Name
                    Extent     = $ast.Extent | Select-Object File, StartLineNumber, EndLineNumber
                    Definition = $ast.Extent.ToString()
                    PSTypeName = 'Indented.ClassInfo'
                }
            }
        } catch {
            Write-Error -ErrorRecord $_
        }
    }
}