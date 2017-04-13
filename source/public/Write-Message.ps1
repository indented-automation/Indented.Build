function Write-Message {
    param(
        [String]$Object,

        [ConsoleColor]$ForegroundColor
    )

    $null = $psboundparameters.Remove('Quiet')
    if (-not $Script:Quiet) {
        Write-Host
        Write-Host @psboundparameters
        Write-Host
    }
}