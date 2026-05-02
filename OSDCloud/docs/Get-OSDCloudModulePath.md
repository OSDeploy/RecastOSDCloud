---
external help file: OSDCloud-help.xml
Module Name: OSDCloud
online version:
schema: 2.0.0
---

# Get-OSDCloudModulePath

## SYNOPSIS
Returns the base directory path of the OSDCloud module.

## SYNTAX

```
Get-OSDCloudModulePath [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the file system path to the root folder where the OSDCloud module is installed.
This is useful for locating module-relative resources such as catalogs, templates, and support files.

## EXAMPLES

### EXAMPLE 1
```
Get-OSDCloudModulePath
```

Returns the path to the OSDCloud module directory, e.g.
'C:\Program Files\WindowsPowerShell\Modules\OSDCloud\1.0.0'.

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

### System.String. The absolute path to the OSDCloud module directory.
## NOTES

## RELATED LINKS
