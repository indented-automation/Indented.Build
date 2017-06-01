---
external help file: Indented.Build-help.xml
online version: 
schema: 2.0.0
---

# Export-BuildScript

## SYNOPSIS
Export a persistent build script.

## SYNTAX

```
Export-BuildScript [[-BuildInfo] <PSObject>] [[-BuildSystem] <String>]
```

## DESCRIPTION
Export a persistent build script (as .build.ps1).

## EXAMPLES

### Example 1
```
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -BuildInfo
The build information object is used to determine which tasks are applicable.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: (Get-BuildInfo)
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -BuildSystem
By default the build system is automatically discovered.
The BuildSystem parameter overrides any automatically discovered value.
Tasks associated with the build system are added to the generated script.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### BuildInfo (from Get-BuildInfo)

## OUTPUTS

### System.Void

## NOTES

## RELATED LINKS

