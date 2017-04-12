BuildTask TestSyntax -Stage Build -Properties {
    Order          = 0
    Implementation = {
        $hasSyntaxErrors = $false
        foreach ($path in 'public', 'private', 'InitializeModule.ps1') {
            $path = Join-Path 'source' $path
            if (Test-Path $path) {
                Get-ChildItem $path -Filter *.ps1 -File -Recurse |
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
            }
        }
        if ($hasSyntaxErrors) {
            throw 'TestSyntax failed'
        }
    }
}