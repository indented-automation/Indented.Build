---
external help file: Indented.Build-help.xml
Module Name: Indented.Build
online version:
schema: 2.0.0
---

# Convert-CodeCoverage

## SYNOPSIS
Converts code coverage line and file reference from root module to file.

## SYNTAX

```
Convert-CodeCoverage [-CodeCoverage] <PSObject> -BuildInfo <PSObject> [-Tee] [<CommonParameters>]
```

## DESCRIPTION
When tests are executed against a merged module, all lines are relative to the psm1 file.

This command updates line references to match the development file set.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -CodeCoverage
The original code coverage report.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -BuildInfo
The output from Get-BuildInfo for this project.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tee
Write missed commands using format table as they are discovered.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
