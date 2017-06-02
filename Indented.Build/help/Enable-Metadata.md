---
external help file: Indented.Build-help.xml
online version: 
schema: 2.0.0
---

# Enable-Metadata

## SYNOPSIS
Enable a metadata property which has been commented out.

## SYNTAX

```
Enable-Metadata [[-Path] <String>] [-PropertyName <String>]
```

## DESCRIPTION
This function is derived Get and Update-Metadata from PoshCode\Configuration.

A boolean value is returned indicating if the property is available in the metadata file.

If the property does not exist, or exists more than once within the specified file this command will return false.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
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

## INPUTS

### System.String

## OUTPUTS

### System.Boolean

## NOTES
Change log:
    04/08/2016 - Chris Dent - Created.

## RELATED LINKS

