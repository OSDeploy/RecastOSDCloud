---
external help file: OSDCloud-help.xml
Module Name: OSDCloud
online version: https://github.com/OSDeploy/OSDCloud/blob/main/PRIVACY.md
schema: 2.0.0
---

# Get-OSDCloudCache

## SYNOPSIS
Returns OSDCloud cache paths or cached content found on local file system drives.

## SYNTAX

```
Get-OSDCloudCache [[-Type] <String[]>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Enumerates mounted file system drives and discovers OSDCloud cache content.
Returns objects with Type, FullName, SizeMB,
DriveRoot, VolumeLabel, and VolumeUniqueId properties.

If Type is omitted, returns discovered '\<DriveLetter\>:\OSDCloud' cache root
folders as Type 'Cache'.

Type values:
- ESD: All .esd files under '\<DriveLetter\>:\OSDCloud\OS' recursively.
- ISO: All .iso files under '\<DriveLetter\>:\OSDCloud\ISO' recursively.
- DriverPacks: All .cab, .exe, .msi, and .zip files under
  '\<DriveLetter\>:\OSDCloud\DriverPacks' recursively.
- Drivers: Immediate folders under '\<DriveLetter\>:\OSDCloud\Drivers' that
  contain at least one .inf file in any child folder.
        - Profiles: Immediate folders under '\<DriveLetter\>:\OSDCloud\Profiles'.
- WIM: All .wim files under '\<DriveLetter\>:\OSDCloud\WIM' recursively.
- *: Includes all supported Type values.

## EXAMPLES

### EXAMPLE 1
```
Get-OSDCloudCache
```

Returns paths such as 'C:\OSDCloud' and 'D:\OSDCloud' when present.

### EXAMPLE 2
```
Get-OSDCloudCache -Type ESD
```

Returns all .esd files under each discovered cache OS folder.

### EXAMPLE 3
```
Get-OSDCloudCache -Type ESD,DriverPacks
```

Returns all .esd files and driver pack files from each discovered cache.

### EXAMPLE 4
```
Get-OSDCloudCache -Type *
```

Returns all supported cache content types.

## PARAMETERS

### -Type
Optional cache content selector.

Supports one or more values.
Use '*' to return all supported
cache content types.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

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

### System.Object[]. Objects with Type, FullName, SizeMB,
### DriveRoot, VolumeLabel, and VolumeUniqueId.
## NOTES

## RELATED LINKS
