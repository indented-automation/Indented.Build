BuildTask TestAttributeSyntax -Stage Test -Order 1 -Definition {
    # Attempt to test whether or not attributes used within a script contain errors.
    #
    # If an attribute does not appear to exist it is compared with a list of common attributes from the System.Management.Automation namespace and any classes declared within the module.
    #
    # If the non-existent attribute has a Levenshtein distance less than 3 from a known attribute it will be flagged as a typo and the build will fail.
    #
    # Otherwise the author is assumed to have implemented and used a new attribute which is declared elsewhere.

    $script = {
        param (
            $buildInfo
        )

        Import-Module $buildInfo.Path.Build.Manifest

        $commonAttributes = [PowerShell].Assembly.GetTypes() |
            Where-Object { $_.Name -match 'Attribute$' -and $_.IsPublic } |
            ForEach-Object {
                $_.Name
                $_.Name -replace 'Attribute$'
            }

        $hasSyntaxErrors = $false
        $tokens = $null
        [System.Management.Automation.Language.ParseError[]]$parseErrors = @()
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $buildInfo.Path.Build.RootModule,
            [Ref]$tokens,
            [Ref]$parseErrors
        )
        $moduleClasses = $ast.FindAll(
            {
                param ( $childAst )

                $childAst -is [System.Management.Automation.Language.TypeDefinitionAst] -and
                $childAst.IsClass
            },
            $true
        ) | Group-Object Name -AsHashTable -AsString

        $attributes = $ast.FindAll(
            {
                param ( $childAst )

                $childAst -is [System.Management.Automation.Language.AttributeAst]
            },
            $true
        )
        foreach ($attribute in $attributes) {
            if ($moduleClasses -and $moduleClasses.Contains($attribute.TypeName.FullName)) {
                continue
            } elseif (($type = $attribute.TypeName.FullName -as [Type]) -or ($type = ('{0}Attribute' -f $attribute.TypeName.FullName) -as [Type])) {
                $propertyNames = $type.GetProperties().Name

                if ($attribute.NamedArguments.Count -gt 0) {
                    foreach ($argument in $attribute.NamedArguments) {
                        if ($argument.ArgumentName -notin $propertyNames) {
                            Write-Warning ('Invalid property name in attribute declaration: {0} at line {1}' -f @(
                                $argument.ArgumentName
                                $argument.Extent.StartLineNumber
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

                $message = 'Unknown attribute declared: {0} at line {1}.'
                if ($closestMatch) {
                    $message = '{0} Suggested name: {1}' -f @(
                        $message
                        $closestMatch.DifferenceString
                    )
                    $hasSyntaxErrors = $true
                }

                Write-Warning ($message -f @(
                    $attribute.TypeName.FullName
                    $attribute.Extent.StartLineNumber
                ))

            }
        }

        return $hasSyntaxErrors
    }

    if ($buildInfo.BuildSystem -eq 'Desktop') {
        $hasSyntaxErrors = Start-Job -ArgumentList $buildInfo -ScriptBlock $script | Receive-Job -Wait
    } else {
        $hasSyntaxErrors = & $script -BuildInfo $buildInfo
    }

    if ($hasSyntaxErrors) {
        throw 'TestAttributeSyntax failed'
    }
}