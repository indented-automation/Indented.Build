---
external help file: Indented.Build-help.xml
Module Name: Indented.Build
online version:
schema: 2.0.0
---

# Get-ClassInfo

## SYNOPSIS
Get information about a class implemented in PowerShell.

## SYNTAX

### FromPath (Default)
```
Get-ClassInfo [[-Path] <String>] [<CommonParameters>]
```

### FromScriptBlock
```
Get-ClassInfo [-ScriptBlock <ScriptBlock>] [<CommonParameters>]
```

## DESCRIPTION
Get information about a class implemented in PowerShell.

## EXAMPLES

### EXAMPLE 1
```
Get-ChildItem -Filter *.psm1 | Get-ClassInfo
```

Get all classes declared within the *.psm1 file.

## PARAMETERS

### -Path
The path to a file containing one or more functions.

```yaml
Type: String
Parameter Sets: FromPath
Aliases: FullName

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ScriptBlock
A script block containing one or more functions.

```yaml
Type: ScriptBlock
Parameter Sets: FromScriptBlock
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Indented.ClassInfo
## NOTES

## RELATED LINKS
