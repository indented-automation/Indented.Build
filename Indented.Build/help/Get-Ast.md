---
external help file: Indented.Build-help.xml
Module Name: Indented.Build
online version:
schema: 2.0.0
---

# Get-Ast

## SYNOPSIS
Get the abstract syntax tree for either a file or a scriptblock.

## SYNTAX

### FromPath (Default)
```
Get-Ast [[-Path] <String>] [-Discard <Object>] [<CommonParameters>]
```

### FromScriptBlock
```
Get-Ast [-ScriptBlock <ScriptBlock>] [-Discard <Object>] [<CommonParameters>]
```

## DESCRIPTION
Get the abstract syntax tree for either a file or a scriptblock.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

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

### -Discard
{{ Fill Discard Description }}

```yaml
Type: Object
Parameter Sets: (All)
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

### System.Management.Automation.Language.ScriptBlockAst
## NOTES

## RELATED LINKS
