---
external help file: Indented.Build-help.xml
online version: 
schema: 2.0.0
---

# Get-ChildBuildInfo

## SYNOPSIS
Get items which can be built from child paths of the specified folder.

## SYNTAX

```
Get-ChildBuildInfo [[-Path] <String>] [[-Depth] <Int32>]
```

## DESCRIPTION
A folder may contain one or more items which can be built, this command may be used to discover individual projects.

## EXAMPLES

### Example 1
```
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Path
The starting point for the build search.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: $pwd.Path
Accept pipeline input: False
Accept wildcard characters: False
```

### -Depth
Recurse to the specified depth when attempting to find projects which can be built.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: 4
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### BuildInfo

## NOTES

## RELATED LINKS

