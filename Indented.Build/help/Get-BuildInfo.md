---
external help file: Indented.Build-help.xml
online version: 
schema: 2.0.0
---

# Get-BuildInfo

## SYNOPSIS
Get properties required to build the project.

## SYNTAX

```
Get-BuildInfo [[-BuildType] <String[]>] [[-ReleaseType] <String>] [[-Path] <String>]
```

## DESCRIPTION
Get the properties required to build the project, or elements of the project.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-BuildInfo
```

Get build information for the current or any child directories.

## PARAMETERS

### -BuildType
The tasks to execute, passed to Invoke-Build.
BuildType is expected to be a broad description of the build, encompassing a set of tasks.

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
The release type.
By default the release type is Build and the build version will increment.

If the last commit message includes the phrase "major release" the release type will be reset to Major; If the last commit meessage includes "release" the releasetype will be reset to Minor.

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

### -Path
Generate build informatio for the specified path.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: $pwd.Path
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### BuildInfo

## NOTES

## RELATED LINKS

