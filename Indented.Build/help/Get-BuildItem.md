---
external help file: Indented.Build-help.xml
online version: 
schema: 2.0.0
---

# Get-BuildItem

## SYNOPSIS
Get source items.

## SYNTAX

```
Get-BuildItem [-Type] <String> [-BuildInfo] <PSObject>
```

## DESCRIPTION
Get items from the source tree which will be consumed by the build process.

This function centralises the logic required to enumerate files and folders within a project.

## EXAMPLES

### Example 1
```
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Type
Gets items by type.

  ShouldMerge - *.ps1 files from enum*, class*, priv*, pub* and InitializeModule if present.
  Static      - Files which are not within a well known top-level folder.
Captures help content in en-US, format files, configuration files, etc.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BuildInfo
{{Fill BuildInfo Description}}

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### System.IO.FileInfo

### System.IO.DirectoryInfo

## NOTES

## RELATED LINKS

