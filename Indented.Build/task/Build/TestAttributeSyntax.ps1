BuildTask TestAttributeSyntax -Stage Build -Order 2 -Definition {
    $commonAttributes = [PowerShell].Assembly.GetTypes() |
        Where-Object { $_.Name -match 'Attribute$' -and $_.IsPublic } |
        ForEach-Object {
            $_.Name
            $_.Name -replace 'Attribute$'
        }

    $hasSyntaxErrors = $false
    $buildInfo | Get-BuildItem -Type ShouldMerge -ExcludeClass | ForEach-Object {
        $tokens = $null
        [System.Management.Automation.Language.ParseError[]]$parseErrors = @()
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            (Get-Content $_.FullName -Raw),
            $_.FullName,
            [Ref]$tokens,
            [Ref]$parseErrors
        )

        $attributes = $ast.FindAll(
            { $args[0] -is [System.Management.Automation.Language.AttributeAst] },
            $true
        )
        foreach ($attribute in $attributes) {
            if (($type = $attribute.TypeName.FullName -as [Type]) -or ($type = ('{0}Attribute' -f $attribute.TypeName.FullName) -as [Type])) {
                $propertyNames = $type.GetProperties().Name

                if ($attribute.NamedArguments.Count -gt 0) {
                    foreach ($argument in $attribute.NamedArguments) {
                        if ($argument.ArgumentName -notin $propertyNames) {
                            Write-Warning ('Invalid property name in attribute declaration: {0}: {1} at line {2}, character {3}' -f @(
                                $_.Name
                                $argument.ArgumentName
                                $argument.Extent.StartLineNumber
                                $argument.Extent.StartColumnNumber
                            ))

                            $hasSyntaxErrors = $true
                        }
                    }
                }
            } else {
                $params = @{
                    ReferenceString  = $attribute.TypeName.Name
                }
                $closestMatch = $commonAttributes |
                    Get-LevenshteinDistance @params |
                    Where-Object Distance -lt 3 |
                    Select-Object -First 1

                $message = 'Unknown attribute declared: {0}: {1} at line {2}, character {3}.'
                if ($closestMatch) {
                    $message = '{0} Suggested name: {1}' -f @(
                        $message
                        $closestMatch.DifferenceString
                    )
                    $hasSyntaxErrors = $true
                }

                Write-Warning ($message -f @(
                    $_.Name
                    $attribute.TypeName.FullName
                    $attribute.Extent.StartLineNumber
                    $attribute.Extent.StartColumnNumber
                ))

            }
        }
    }

    if ($hasSyntaxErrors) {
        throw 'TestAttributeSyntax failed'
    }
}