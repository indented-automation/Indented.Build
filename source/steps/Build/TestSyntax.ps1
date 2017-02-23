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

    [BuildStep('Build', Order = 1)]
    param( )

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

                    # Test attribute syntax
                    $attributes = $ast.FindAll( {
                            param( $ast )
                            
                            $ast -is [System.Management.Automation.Language.AttributeAst]
                        },
                        $true
                    )
                    foreach ($attribute in $attributes) {
                        if ($type = $attribute.TypeName.FullName -as [Type]) {
                            $propertyNames = $type.GetProperties().Name

                            if ($attribute.NamedArguments.Count -gt 0) {
                                foreach ($argument in $attribute.NamedArguments) {
                                    if ($argument.ArgumentName -notin $propertyNames) {
                                        $message = 'Invalid property name in attribute declaration: {0} at line {1}, character {2}' -f
                                            $argument.ArgumentName,
                                            $argument.Extent.StartLineNumber,
                                            $argument.Extent.StartColumnNumber

                                        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                                            (New-Object ArgumentException $message),
                                            'InvalidAttributeArgument',
                                            'InvalidArgument',
                                            $attribute
                                        )

                                        Write-Error -ErrorRecord $errorRecord

                                        $hasSyntaxErrors = $true
                                    }
                                }
                            }
                        } else {
                            $message = 'Invalid attribute declaration: {0} at line {1}, character {2}' -f
                                $attribute.TypeName.FullName,
                                $attribute.Extent.StartLineNumber,
                                $attribute.Extent.StartColumnNumber

                            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                                (New-Object ArgumentException $message),
                                'InvalidAttribute',
                                'InvalidArgument',
                                $attribute
                            )

                            Write-Error -ErrorRecord $errorRecord

                        }
                    }
                }
        }
    }
    if ($hasSyntaxErrors) {
        throw 'TestSyntax failed'
    }
}