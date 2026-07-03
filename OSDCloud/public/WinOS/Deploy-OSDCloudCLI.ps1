function Deploy-OSDCloudCLI {
    <#
    .SYNOPSIS
        Starts an OSDCloud operating system deployment in CLI mode.

    .DESCRIPTION
        Initializes and runs an OSDCloud deployment workflow directly in the current
        console session without launching the graphical UX. This function is a CLI-only
        entry point and immediately invokes workflow tasks after initialization.

        In addition to the static -Force parameter, workflow-specific runtime parameters
        are added dynamically from the CLI workflow definition.

    .PARAMETER Force
        Skips confirmation prompts for destructive workflow steps that support force behavior.

    .PARAMETER ProfileName
        The full OS profile name used to resolve the Env file path. Defaults to 'default'.
        Ignored in WinPE.

    .EXAMPLE
        Deploy-OSDCloudCLI

        Runs the default OSDCloud workflow immediately in the current console session.

    .EXAMPLE
        Deploy-OSDCloudCLI -OperatingSystem 'Windows 11 24H2'

        Runs the CLI workflow and overrides the OperatingSystem default.

    .EXAMPLE
        Deploy-OSDCloudCLI -OSEdition 'Enterprise' -OSLanguageCode 'en-gb'

        Runs the CLI workflow with Enterprise edition and en-gb language.

    .EXAMPLE
        Deploy-OSDCloudCLI -Task 'OSDCloud SkipFirmwareUpdate'

        Runs the selected CLI workflow task.

    .EXAMPLE
        Deploy-OSDCloudCLI -Force

        Runs the default workflow and suppresses supported confirmation prompts.

    .EXAMPLE
        Deploy-OSDCloudCLI -ProfileName 'Lab'

        Runs the CLI workflow using the 'Lab' profile Env path.

    .OUTPUTS
        System.Void

    .NOTES
        This function does not display the graphical UX. Workflow execution begins
        immediately after initialization. Runtime parameters are provided by
        Get-OSDCloudWorkflowRuntimeParameter for the 'cli' workflow.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(Mandatory = $false)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

            $profileNames = @('default')
            if ($env:SystemDrive -ne 'X:' -and $env:ProgramData) {
                $profileRoot = Join-Path -Path $env:ProgramData -ChildPath 'OSDeployCore\OSDCloud\Profiles'
                if (Test-Path -Path $profileRoot -PathType Container) {
                    $directoryNames = Get-ChildItem -Path $profileRoot -Directory -ErrorAction SilentlyContinue |
                        Select-Object -ExpandProperty Name
                    if ($directoryNames) {
                        $profileNames += $directoryNames
                    }
                }
            }

            foreach ($profileName in ($profileNames | Sort-Object -Unique)) {
                if ($profileName -like "$wordToComplete*") {
                    [System.Management.Automation.CompletionResult]::new($profileName, $profileName, 'ParameterValue', $profileName)
                }
            }
        })]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ProfileName = 'default'
    )

    dynamicparam {
        $moduleBase = $MyInvocation.MyCommand.Module.ModuleBase
        return Get-OSDCloudWorkflowRuntimeParameter -WorkflowName 'cli' -ModuleBase $moduleBase
    }

    begin {
        Write-Host -ForegroundColor Yellow "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Preview Release: This function is for feedback only. Expect frequent changes before the official release."

        #=================================================
        # Initialize OSDCloudWorkflow
        # Override values (Parameters > ENV) are assembled into $global:OSDCloudEnv
        # and applied to $global:OSDCloudDeploy - including operating system resolution - inside
        # Initialize-OSDCloudDeploy.
        $WorkflowName = 'cli'
        $envParameters = @{}
        if (Get-Command -Name 'ConvertTo-OSDCloudEnvParameter' -ErrorAction SilentlyContinue) {
            $envParameters = ConvertTo-OSDCloudEnvParameter -BoundParameters $PSBoundParameters
        }
        Initialize-OSDCloudDeploy -WorkflowName $WorkflowName -EnvParameters $envParameters -ProfileName $ProfileName

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] OperatingSystem: $($global:OSDCloudDeploy.OperatingSystem)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] OSEdition: $($global:OSDCloudDeploy.OSEdition)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] OSActivation: $($global:OSDCloudDeploy.OSActivation)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] OSLanguageCode: $($global:OSDCloudDeploy.OSLanguageCode)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Task: $($global:OSDCloudDeploy.WorkflowTaskName)"
        #=================================================
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Invoke-OSDCloudWorkflowTask"
        $global:OSDCloudDeploy.TimeStart = Get-Date
        $global:OSDCloudDeploy | Out-Host
        Invoke-OSDCloudWorkflowTask
        #=================================================
    }
}
