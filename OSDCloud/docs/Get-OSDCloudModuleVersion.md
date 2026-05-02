---
external help file: OSDCloud-help.xml
Module Name: OSDCloud
online version:
schema: 2.0.0
---

# Get-OSDCloudModuleVersion

## SYNOPSIS
Returns the version of the OSDCloud module.

## SYNTAX

```
Get-OSDCloudModuleVersion [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the currently loaded version of the OSDCloud module as a System.Version object.
This is useful for version checks, logging, and compatibility validation in scripts.

## EXAMPLES

### EXAMPLE 1
```
Get-OSDCloudModuleVersion
```

Returns the loaded OSDCloud module version, e.g.
'1.0.0'.

## PARAMETERS

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Version. The version of the OSDCloud module.
## NOTES

## RELATED LINKS
