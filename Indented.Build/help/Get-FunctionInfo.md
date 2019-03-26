---
external help file: Indented.Build-help.xml
Module Name: Indented.Build
online version:
schema: 2.0.0
---

# Get-FunctionInfo

## SYNOPSIS
Get an instance of FunctionInfo.

## SYNTAX

### FromPath (Default)
```
Get-FunctionInfo [[-Path] <String>] [-IncludeNested] [<CommonParameters>]
```

### FromScriptBlock
```
Get-FunctionInfo [-ScriptBlock <ScriptBlock>] [-IncludeNested] [<CommonParameters>]
```

## DESCRIPTION
FunctionInfo does not present a public constructor.
This function calls an internal / private constructor on FunctionInfo to create a description of a function from a script block or file containing one or more functions.

## EXAMPLES

### EXAMPLE 1
```
Get-ChildItem -Filter *.psm1 | Get-FunctionInfo
```

Get all functions declared within the *.psm1 file and construct FunctionInfo.

### EXAMPLE 2
```
Get-ChildItem C:\Scripts -Filter *.ps1 -Recurse | Get-FunctionInfo
```

Get all functions declared in all ps1 files in C:\Scripts.

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
Accept pipeline input: True (ByPropertyName)
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

### -IncludeNested
By default functions nested inside other functions are ignored.
Setting this parameter will allow nested functions to be discovered.

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.FunctionInfo
## NOTES

## RELATED LINKS
