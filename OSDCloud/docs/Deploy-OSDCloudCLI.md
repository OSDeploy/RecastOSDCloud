---
external help file: OSDCloud-help.xml
Module Name: OSDCloud
online version: https://github.com/OSDeploy/OSDCloud/blob/main/PRIVACY.md
schema: 2.0.0
---

# Deploy-OSDCloudCLI

## SYNOPSIS
Starts an OSDCloud operating system deployment in CLI mode.

## SYNTAX

```
Deploy-OSDCloudCLI [-Force] [[-ProfileName] <String>] [-ProgressAction <ActionPreference>]
 [-OperatingSystem <String>] [-OSEdition <String>] [-OSActivation <String>] [-OSLanguageCode <String>]
 [-Task <String>] [<CommonParameters>]
```

## DESCRIPTION
Initializes and runs an OSDCloud deployment workflow directly in the current
console session without launching the graphical UX.
This function is a CLI-only
entry point and immediately invokes workflow tasks after initialization.

In addition to the static -Force parameter, workflow-specific runtime parameters
are added dynamically from the CLI workflow definition.

## EXAMPLES

### EXAMPLE 1
```
Deploy-OSDCloudCLI
```

Runs the default OSDCloud workflow immediately in the current console session.

### EXAMPLE 2
```
Deploy-OSDCloudCLI -OperatingSystem 'Windows 11 24H2'
```

Runs the CLI workflow and overrides the OperatingSystem default.

### EXAMPLE 3
```
Deploy-OSDCloudCLI -OSEdition 'Enterprise' -OSLanguageCode 'en-gb'
```

Runs the CLI workflow with Enterprise edition and en-gb language.

### EXAMPLE 4
```
Deploy-OSDCloudCLI -Task 'OSDCloud SkipFirmwareUpdate'
```

Runs the selected CLI workflow task.

### EXAMPLE 5
```
Deploy-OSDCloudCLI -Force
```

Runs the default workflow and suppresses supported confirmation prompts.

### EXAMPLE 6
```
Deploy-OSDCloudCLI -ProfileName 'Lab'
```

Runs the CLI workflow using the 'Lab' profile Env path.

## PARAMETERS

### -Force
Skips confirmation prompts for destructive workflow steps that support force behavior.

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

### -ProfileName
The full OS profile name used to resolve the Env file path.
Defaults to 'default'.
Ignored in WinPE.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Default
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperatingSystem
{{ Fill OperatingSystem Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OSActivation
{{ Fill OSActivation Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OSEdition
{{ Fill OSEdition Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OSLanguageCode
{{ Fill OSLanguageCode Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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

### -Task
{{ Fill Task Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

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

### System.Void
## NOTES
This function does not display the graphical UX.
Workflow execution begins
immediately after initialization.
Runtime parameters are provided by
Get-OSDCloudWorkflowRuntimeParameter for the 'cli' workflow.

## RELATED LINKS
