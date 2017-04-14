function Write-Message {
    # .SYNOPSIS
    #   Writes a message to the console.
    # .DESCRIPTION
    #   Writes a message to the console.

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    [CmdletBinding()]
    [OutputType([Void])]
    param (
        [String]$Object,

        [ConsoleColor]$ForegroundColor,

        [Switch]$NoNewLine,
        
        [Switch]$Quiet,

        [Switch]$WithPadding
    )

    $null = $psboundparameters.Remove('Quiet')
    $null = $psboundparameters.Remove('WithPadding')
    if (-not $Quiet) {
        if ($WithPadding) {
            Write-Host
        }
        Write-Host @psboundparameters
        if ($WithPadding) {
            Write-Host
        }
    }
}