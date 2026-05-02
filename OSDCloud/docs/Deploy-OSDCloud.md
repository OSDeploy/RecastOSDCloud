---
external help file: OSDCloud-help.xml
Module Name: OSDCloud
online version:
schema: 2.0.0
---

# Deploy-OSDCloud

## SYNOPSIS
Starts an OSDCloud operating system deployment.

## SYNTAX

```
Deploy-OSDCloud [[-WorkflowName] <String>] [-CLI] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Initializes and runs an OSDCloud deployment workflow.
By default, launches the
graphical UI (UX) so the operator can configure deployment settings before
starting.
Use -CLI to skip the UI and immediately begin the workflow in the
current console session.

OSDCloud collects anonymous analytic data about the deployment environment and
system configuration to help improve the product.
No personally identifiable
information (PII) is collected.
By using OSDCloud you consent to this collection
as described in the privacy policy:
https://github.com/OSDeploy/OSDCloud/blob/main/PRIVACY.md

## EXAMPLES

### EXAMPLE 1
```
Deploy-OSDCloud
```

Launches the OSDCloud graphical UX for the default workflow.
The deployment
starts only after the operator clicks Start in the UI.

### EXAMPLE 2
```
Deploy-OSDCloud -CLI
```

Runs the default OSDCloud workflow immediately without the graphical UX.

### EXAMPLE 3
```
Deploy-OSDCloud -WorkflowName 'latest'
```

Launches the graphical UX for the 'latest' workflow.

## PARAMETERS

### -WorkflowName
The name of the OSDCloud workflow to run.
Defaults to 'default'.
Available workflows are located in the module's workflow folder.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

Required: False
Position: 1
Default value: Default
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CLI
Skips the graphical UX and runs the deployment workflow immediately in the
current console session.

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
