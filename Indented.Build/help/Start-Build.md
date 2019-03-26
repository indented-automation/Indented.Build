---
external help file: Indented.Build-help.xml
Module Name: Indented.Build
online version:
schema: 2.0.0
---

# Start-Build

## SYNOPSIS
Start a build.

## SYNTAX

```
Start-Build [[-BuildType] <String[]>] [[-ReleaseType] <String>] [[-BuildInfo] <PSObject[]>]
 [[-ScriptName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Start a build using Invoke-Build.
If a build script is not present one will be created.

If a build script exists it will be used.
If the build script exists this command is superfluous.

## EXAMPLES

### Example 1
```powershell
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
Default value: ('Setup', 'Build', 'Test')
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
Type: PSObject[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: (Get-BuildInfo)
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ScriptName
{{Fill ScriptName Description}}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: .build.ps1
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
