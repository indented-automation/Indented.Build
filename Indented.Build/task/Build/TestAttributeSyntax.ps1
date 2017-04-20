BuildTask TestAttributeSyntax -Stage Build -Properties @{
    Order          = 2
    Implementation = {
        $hasSyntaxErrors = $false
        Get-ChildItem 'public', 'private', 'InitializeModule.ps1' -Filter *.ps1 -File -Recurse -ErrorAction SilentlyContinue |
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

                # Test attribute syntax
                $attributes = $ast.FindAll( {
                        param( $ast )
                        
                        $ast -is [System.Management.Automation.Language.AttributeAst]
                    },
                    $true
                )
                foreach ($attribute in $attributes) {
                    if (($type = $attribute.TypeName.FullName -as [Type]) -or ($type = ('{0}Attribute' -f $attribute.TypeName.FullName) -as [Type])) {
                        $propertyNames = $type.GetProperties().Name

                        if ($attribute.NamedArguments.Count -gt 0) {
                            foreach ($argument in $attribute.NamedArguments) {
                                if ($argument.ArgumentName -notin $propertyNames) {
                                    'Invalid property name in attribute declaration: {0}: {1} at line {2}, character {3}' -f
                                        $_.Name,
                                        $argument.ArgumentName,
                                        $argument.Extent.StartLineNumber,
                                        $argument.Extent.StartColumnNumber

                                    $hasSyntaxErrors = $true
                                }
                            }
                        }
                    } else {
                        'Invalid attribute declaration: {0}: {1} at line {2}, character {3}' -f
                            $_.Name,
                            $attribute.TypeName.FullName,
                            $attribute.Extent.StartLineNumber,
                            $attribute.Extent.StartColumnNumber

                        $hasSyntaxErrors = $true
                    }
                }
            }
        if ($hasSyntaxErrors) {
            throw 'TestAttributeSyntax failed'
        }
    }
}