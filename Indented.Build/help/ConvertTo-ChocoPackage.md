---
external help file: Indented.Build-help.xml
Module Name: Indented.Build
online version:
schema: 2.0.0
---

# ConvertTo-ChocoPackage

## SYNOPSIS
Convert a PowerShell module into a chocolatey package.

## SYNTAX

```
ConvertTo-ChocoPackage [-InputObject] <Object> [[-Path] <String>] [[-CacheDirectory] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Convert a PowerShell module into a chocolatey package.

## EXAMPLES

### EXAMPLE 1
```
Find-Module pester | ConvertTo-ChocoPackage
```

Find the module pester on a PS repository and convert the module to a chocolatey package.

### EXAMPLE 2
```
Get-Module SqlServer -ListAvailable | ConvertTo-ChocoPackage
```

Get the installed module SqlServer and convert the module to a chocolatey package.

### EXAMPLE 3
```
Find-Module VMware.PowerCli | ConvertTo-ChocoPackage
```

Find the module VMware.PowerCli on a PS repository and convert the module, and all dependencies, to chocolatey packages.

## PARAMETERS

### -InputObject
The module to package.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Path
Write the generated nupkg file to the specified folder.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: .
Accept pipeline input: False
Accept wildcard characters: False
```

### -CacheDirectory
A temporary directory used to stage the choco package content before packing.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: (Join-Path $env:TEMP (New-Guid))
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
