---
external help file: OSDCloud-help.xml
Module Name: OSDCloud
online version:
schema: 2.0.0
---

# Start-OSDCloudExplorer

## SYNOPSIS
Opens a graphical file browser for WinPE and WinRE environments.

## SYNTAX

```
Start-OSDCloudExplorer [-DirectLaunch] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Provides a Windows Forms file browser with TreeView, ListView, navigation
(Up), and keyboard shortcuts.
Designed for use in
Windows PE and Windows RE where Windows Explorer is not available.

The WinPE image must include:
  - WinPE-NetFX
  - WinPE-PowerShell

## EXAMPLES

### EXAMPLE 1
```
Start-OSDCloudExplorer
```

Opens the file browser.
Use the CopyPath button or Ctrl+C to copy
a path to the clipboard.

## PARAMETERS

### -DirectLaunch
Internal: run the WinForms UI inline (blocking) inside the spawned child process.
Not intended for direct use - hidden from tab-completion.

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

## NOTES

## RELATED LINKS
