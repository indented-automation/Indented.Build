---
external help file: Indented.Build-help.xml
Module Name: Indented.Build
online version:
schema: 2.0.0
---

# Get-BuildTask

## SYNOPSIS
Get build tasks.

## SYNTAX

### ForBuild (Default)
```
Get-BuildTask [-BuildInfo] <PSObject> [-Name <String>] [<CommonParameters>]
```

### List
```
Get-BuildTask [-Name <String>] [-ListAvailable] [<CommonParameters>]
```

## DESCRIPTION
Get the build tasks deemed to be applicable to this build.

If the ListAvailable parameter is supplied, all available tasks will be returned.

## EXAMPLES

### Example 1
```powershell
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### BuildTask
## NOTES

## RELATED LINKS
