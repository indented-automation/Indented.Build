---
external help file: Indented.Build-help.xml
online version: 
schema: 2.0.0
---

# Get-BuildTask

## SYNOPSIS
Get build tasks.

## SYNTAX

### ForBuild (Default)
```
Get-BuildTask [-BuildInfo] <PSObject> [-Name <String>]
```

### List
```
Get-BuildTask [-Name <String>] [-ListAvailable]
```

## DESCRIPTION
Get the build tasks deemed to be applicable to this build.

If the ListAvailable parameter is supplied, all available tasks will be returned.

## EXAMPLES

### Example 1
```
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -BuildInfo
A build information object used to determine which tasks will apply to the current build.

```yaml
Type: PSObject
Parameter Sets: ForBuild
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
Filter tasks by task name.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -ListAvailable
List all available tasks, irrespective of conditions applied to the task.

```yaml
Type: SwitchParameter
Parameter Sets: List
Aliases: 

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### BuildTask

## NOTES

## RELATED LINKS

