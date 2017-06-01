---
external help file: Indented.Build-help.xml
online version: 
schema: 2.0.0
---

# Start-Build

## SYNOPSIS
Start a build.

## SYNTAX

```
Start-Build [[-BuildType] <String[]>] [[-ReleaseType] <String>] [[-BuildInfo] <PSObject>]
```

## DESCRIPTION
Start a build using the built-in task executor.

## EXAMPLES

### Example 1
```
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -BuildType
The task categories to execute.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: @('Setup', 'Build', 'Test')
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReleaseType
The release type to create.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: Build
Accept pipeline input: False
Accept wildcard characters: False
```

### -BuildInfo
{{Fill BuildInfo Description}}

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: (Get-BuildInfo -BuildType $BuildType -ReleaseType $ReleaseType)
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### TaskInfo

## NOTES

## RELATED LINKS

