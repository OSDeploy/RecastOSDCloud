function Deploy-OSDCloudCLI {
    <#
    .SYNOPSIS
        Starts an OSDCloud operating system deployment in CLI mode.

    .DESCRIPTION
        Initializes and runs an OSDCloud deployment workflow directly in the current
        console session without launching the graphical UX. This function is a CLI-only
        entry point and immediately invokes workflow tasks after initialization.

    .PARAMETER WorkflowName
        The name of the OSDCloud workflow to run. Defaults to 'default'.
        Available workflows are located in the module's workflow folder.

    .PARAMETER SkipFirmwareUpdate
        Skips firmware update download and apply steps in the workflow.

    .EXAMPLE
        Deploy-OSDCloudCLI

        Runs the default OSDCloud workflow immediately in the current console session.

    .EXAMPLE
        Deploy-OSDCloudCLI -WorkflowName 'latest'

        Runs the 'latest' workflow immediately in the current console session.

    .EXAMPLE
        Deploy-OSDCloudCLI -SkipFirmwareUpdate

        Runs the default workflow and skips firmware update steps.

    .OUTPUTS
        System.Void

    .NOTES
        This function does not display the graphical UX. Workflow execution begins
        immediately after initialization.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [System.String]
        $WorkflowName = 'default',

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]
        $SkipFirmwareUpdate
    )
    #=================================================
    # Initialize OSDCloudWorkflow
    Initialize-OSDCloudDeploy -WorkflowName $WorkflowName
    $global:OSDCloudDeploy.SkipFirmwareUpdate = $SkipFirmwareUpdate.IsPresent
    #=================================================
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask"
    $global:OSDCloudDeploy.TimeStart = Get-Date
    $global:OSDCloudDeploy | Out-Host
    Invoke-OSDCloudWorkflowTask
    #=================================================
}
