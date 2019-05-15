---
external help file: Indented.Build-help.xml
Module Name: Indented.Build
online version:
schema: 2.0.0
---

# Get-BuildInfo

## SYNOPSIS
Get properties required to build the project.

## SYNTAX

```
Get-BuildInfo [[-ModuleName] <String>] [[-ProjectRoot] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get the properties required to build the project, or elements of the project.

## EXAMPLES

### EXAMPLE 1
```
Get-BuildInfo
```

Get build information for the current or any child directories.

## PARAMETERS

### -ModuleName
{{ Fill ModuleName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProjectRoot
Generate build information for the specified path.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: $pwd.Path
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Indented.BuildInfo
## NOTES

## RELATED LINKS
