---
external help file: Indented.Build-help.xml
Module Name: Indented.Build
online version:
schema: 2.0.0
---

# Export-BuildScript

## SYNOPSIS
Export a build script for use with Invoke-Build.

## SYNTAX

```
Export-BuildScript [[-BuildInfo] <PSObject>] [[-BuildSystem] <String>] [[-Path] <String>] [<CommonParameters>]
```

## DESCRIPTION
Export a build script for use with Invoke-Build.

## EXAMPLES

### Example 1
```powershell
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

### -Path
The build script will be written to the the specified path.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: .build.ps1
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### BuildInfo (from Get-BuildInfo)
## OUTPUTS

### System.String
## NOTES

## RELATED LINKS
