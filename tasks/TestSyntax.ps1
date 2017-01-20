function TestSyntax {
    # Test all files which will be merged for syntax errors.

    Get-ChildItem 'source\public', 'source\private', 'InitializeModule.ps1' -Filter *.ps1 -File -Recurse | Where-Object Extension -eq '.ps1' |
        Where-Object Length -gt 0 |
        ForEach-Object {
            Write-Verbose -Message ('TestSyntax: Checking {0}' -f $_.FullName)

            $tokens = $null
            [System.Management.Automation.Language.ParseError[]]$parseErrors = @()
            $null = [System.Management.Automation.Language.Parser]::ParseInput(
                (Get-Content $_.FullName -Raw),
                $_.FullName,
                [Ref]$tokens,
                [Ref]$parseErrors
            )
            if ($parseErrors.Count -gt 0) {
                $buildInfo.State = 'Failed'

                foreach ($parseError in $parseErrors) {
                    [PSCustomObject]@{
                        Path    = $_.FullName.Replace($pwd, '').TrimStart('\')
                        Message = $parseError.Message
                        Line    = $parseError.Extent.StartLineNumber
                        Column  = $parseError.Extent.StartColumnNumber
                    }
                }
            }
        }
}