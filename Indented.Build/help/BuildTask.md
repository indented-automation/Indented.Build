---
external help file: Indented.Build-help.xml
Module Name: Indented.Build
online version:
schema: 2.0.0
---

# BuildTask

## SYNOPSIS
Create a build task object.

## SYNTAX

```
BuildTask [-Name] <String> [-Stage] <String> [[-Order] <Int32>] [[-If] <ScriptBlock>]
 [-Definition] <ScriptBlock> [<CommonParameters>]
```

## DESCRIPTION
A build task is a predefined task used to build well-structured PowerShell projects.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Name
The name of the task.

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

### -Stage
The stage during which the task will be invoked.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Order
Where the task should appear in the build order respective to the stage.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 1024
Accept pipeline input: False
Accept wildcard characters: False
```

### -If
The task will only be invoked if the filter condition is true.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: { $true }
Accept pipeline input: False
Accept wildcard characters: False
```

### -Definition
The task implementation.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Indented.BuildTask
## NOTES

## RELATED LINKS
