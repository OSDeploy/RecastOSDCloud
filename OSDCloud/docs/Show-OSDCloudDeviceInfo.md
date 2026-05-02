---
external help file: OSDCloud-help.xml
Module Name: OSDCloud
online version:
schema: 2.0.0
---

# Show-OSDCloudDeviceInfo

## SYNOPSIS
Displays comprehensive WinPE and device hardware information during OS deployment startup.

## SYNTAX

```
Show-OSDCloudDeviceInfo [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gathers and displays detailed hardware and environment information in Windows PE including system specifications, device identifiers, processor details, memory configuration, disk drives, and network adapters.
Initializes the OSDCloud device environment and exports hardware WMI information to log files in the temporary directory.
Validates system memory requirements and provides warnings if minimum specifications are not met.

## EXAMPLES

### EXAMPLE 1
```
Show-OSDCloudDeviceInfo
Runs Show-OSDCloudDeviceInfo to display comprehensive WinPE and device information including hardware specifications and device identifiers.
```

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

### None. This function displays system information to the console and exports hardware data to log files but does not return objects.
## NOTES
This function is designed for use in Windows PE startup environments and performs the following operations:

Information Displayed:
- OSDCloud PowerShell Module version
- WinPE version, architecture, and computer name
- Device manufacturer and model
- BIOS information
- Processor name and logical core count
- Total physical memory in GB
- Disk drive models and device IDs
- Network adapter names and MAC addresses

Note: Serial number and UUID output are suppressed for privacy reasons.

System Requirements:
- Minimum 6 GB of physical memory recommended
- Issues warning if memory is less than 6 GB

Log Files Created:
- Stores device information in $env:TEMP\osdcloud-logs directory
- Win32_DiskDrive.txt: Complete disk drive information
- Win32_NetworkAdapter.txt: Complete network adapter information

Functions Called:
- Get-OSDCloudModuleVersion: Retrieves current OSDCloud module version
- Initialize-OSDCloudDevice: Populates $global:OSDCloudDevice with hardware details

The function updates the window title to '\[OSDCloud\] - WinPE and Device Information' to indicate the current operation status.

## RELATED LINKS
