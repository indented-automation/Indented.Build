---
external help file: Indented.Build-help.xml
Module Name: Indented.Build
online version:
schema: 2.0.0
---

# Enable-Metadata

## SYNOPSIS
Enable a metadata property which has been commented out.

## SYNTAX

```
Enable-Metadata [[-Path] <String>] [-PropertyName <String>] [<CommonParameters>]
```

## DESCRIPTION
This function is derived Get and Update-Metadata from PoshCode\Configuration.

A boolean value is returned indicating if the property is available in the metadata file.

If the property does not exist, or exists more than once within the specified file this command will return false.

## EXAMPLES

### EXAMPLE 1
```
Enable-Metadata .\module.psd1 -PropertyName RequiredAssemblies
```

Enable an existing (commented) RequiredAssemblies property within the module.psd1 file.

## PARAMETERS

### -Path
A valid metadata file or string containing the metadata.

```yaml
Type: String
Parameter Sets: (All)
Aliases: PSPath

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PropertyName
The property to enable.

```yaml
Type: String
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

### System.String
## OUTPUTS

### System.Boolean
## NOTES

## RELATED LINKS
