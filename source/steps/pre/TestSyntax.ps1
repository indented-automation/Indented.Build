function TestSyntax {
    # .SYNOPSIS
    #   Test for syntax errors in .ps1 files.
    # .DESCRIPTION
    #   Test for syntax errors in InitializeModule and all .ps1 files (recursively) beneath:
    #
    #     * pwd\source\public
    #     * pwd\source\private
    #
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     01/02/2017 - Chris Dent - Added help.

    $hasSyntaxErrors = $false
    Get-ChildItem 'source\public', 'source\private', 'InitializeModule.ps1' -Filter *.ps1 -File -Recurse |
        Where-Object { $_.Extension -eq '.ps1' -and $_.Length -gt 0 } |
        ForEach-Object {
            $tokens = $null
            [System.Management.Automation.Language.ParseError[]]$parseErrors = @()
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
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