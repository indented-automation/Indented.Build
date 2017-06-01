---
external help file: Indented.Build-help.xml
online version: 
schema: 2.0.0
---

# Invoke-BuildTask

## SYNOPSIS
Invoke a build step.

## SYNTAX

```
Invoke-BuildTask [-BuildTask] <PSObject> [-BuildInfo] <PSObject> [-TaskInfo] <PSReference> [-Quiet]
```

## DESCRIPTION
An output display wrapper to show progress through a build.

## EXAMPLES

### Example 1
```
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -BuildTask
The task to invoke.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -BuildInfo
Task execution context information.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TaskInfo
A reference to a PSObject which is used to return detailed execution information as an object.

```yaml
Type: PSReference
Parameter Sets: (All)
Aliases: 

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet
Suppress informational messages.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES
Change log:
    01/02/2017 - Chris Dent - Added help.

## RELATED LINKS

