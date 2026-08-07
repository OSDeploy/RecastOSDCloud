function Deploy-OSDCloud {
    <#
    .SYNOPSIS
        Starts an OSDCloud operating system deployment.

    .DESCRIPTION
        Initializes and runs an OSDCloud deployment workflow. By default, launches the
        graphical UI (UX) so the operator can configure deployment settings before
        starting. Use -CLI to skip the UI and immediately begin the workflow in the
        current console session.

        In addition to the static parameters documented here, workflow-specific runtime
        parameters are added dynamically from the selected workflow definition.

        OSDCloud collects anonymous analytic data about the deployment environment and
        system configuration to help improve the product. No personally identifiable
        information (PII) is collected. By using OSDCloud you consent to this collection
        as described in the privacy policy:
        https://github.com/OSDeploy/OSDCloud/blob/main/PRIVACY.md

    .PARAMETER WorkflowName
        The name of the OSDCloud workflow to run. Defaults to 'default'.
        Available workflows are located in the module's workflow folder.

    .PARAMETER CLI
        Skips the graphical UX and runs the deployment workflow immediately in the
        current console session.

    .PARAMETER Force
        Suppresses supported confirmation prompts for destructive workflow steps.

    .PARAMETER ProfileName
        The full OS profile name used to resolve the Env file path. Defaults to 'default'.
        Ignored in WinPE.

    .EXAMPLE
        Deploy-OSDCloud

        Launches the OSDCloud graphical UX for the default workflow. The deployment
        starts only after the operator clicks Start in the UI.

    .EXAMPLE
        Deploy-OSDCloud -CLI

        Runs the default OSDCloud workflow immediately without the graphical UX.

    .EXAMPLE
        Deploy-OSDCloud -WorkflowName 'latest'

        Launches the graphical UX for the 'latest' workflow.

    .EXAMPLE
        Deploy-OSDCloud -CLI -OperatingSystem 'Windows 11 24H2' -OSEdition 'Enterprise'

        Runs in CLI mode using dynamic runtime overrides from the selected workflow.

    .EXAMPLE
        Deploy-OSDCloud -ProfileName 'Lab'

        Launches the OSDCloud graphical UX using the 'Lab' profile Env path.

    .OUTPUTS
        System.Void

    .NOTES
        This command writes deployment status to the host and starts workflow tasks.
        In GUI mode, workflow execution starts only after the operator clicks Start.
        Runtime parameters are provided by Get-OSDCloudWorkflowRuntimeParameter.

    .LINK
        https://github.com/OSDeploy/OSDCloud/blob/main/PRIVACY.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [System.String]
        $WorkflowName = 'default',

        [System.Management.Automation.SwitchParameter]
        $CLI,

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
        $ProfileName = 'default',

        [Parameter(Mandatory = $false, HelpMessage = 'Optional manufacturer override used for driver pack selection.')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OSDManufacturer,

        [Parameter(Mandatory = $false, HelpMessage = 'Optional model override used for driver pack selection.')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OSDModel,

        [Parameter(Mandatory = $false, HelpMessage = 'Optional product/system ID override used for driver pack selection.')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OSDProduct,

        [Parameter(Mandatory = $false, HelpMessage = 'Operating system architecture for deployment selection.')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('amd64','arm64')]
        [System.String]
        $OSArchitecture = $env:PROCESSOR_ARCHITECTURE
    )

    dynamicparam {
        $moduleBase = $($MyInvocation.MyCommand.Module.ModuleBase)
        $resolvedWorkflowName = if ($PSBoundParameters.ContainsKey('WorkflowName')) { [System.String]$PSBoundParameters['WorkflowName'] } else { 'default' }
        return Get-OSDCloudWorkflowRuntimeParameter -WorkflowName $resolvedWorkflowName -ModuleBase $moduleBase
    }

    end {
        #=================================================
        $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [INFO] [$($MyInvocation.MyCommand.Name)] $ModuleVersion"

        Write-Host -ForegroundColor DarkCyan 'OSDCloud collects analytic data during the deployment process to help improve the product and user experience.'
        Write-Host -ForegroundColor DarkCyan 'No personally identifiable information (PII) is collected, and all data is anonymized to protect user privacy.'
        Write-Host -ForegroundColor DarkCyan 'Collected data includes information about the deployment environment and system configuration.'
        Write-Host -ForegroundColor DarkCyan 'By using OSDCloud, you consent to the collection of analytic data as outlined in the privacy policy:'
        Write-Host -ForegroundColor DarkGray 'https://github.com/OSDeploy/OSDCloud/blob/main/PRIVACY.md'
        Write-Host
        #=================================================
        # Initialize Device and Deployment Objects
        Initialize-OSDCoreDevice

        # Populate variables from environment and profile settings, and apply any parameter overrides.
        $envParameters = @{}
        if (Get-Command -Name 'ConvertTo-OSDCloudEnvParameter' -ErrorAction SilentlyContinue) {
            $envParameters = ConvertTo-OSDCloudEnvParameter -BoundParameters $PSBoundParameters
        }
        #=================================================
        # OSDCoreDevice Manufacturer, Model, Product overrides
        if ($OSDManufacturer -and -not [string]::IsNullOrWhiteSpace($OSDManufacturer)) {
            $global:OSDCoreDevice.OSDManufacturer = $OSDManufacturer
        }
        if ($OSDModel -and -not [string]::IsNullOrWhiteSpace($OSDModel)) {
            $global:OSDCoreDevice.OSDModel = $OSDModel
        }
        if ($OSDProduct -and -not [string]::IsNullOrWhiteSpace($OSDProduct)) {
            $global:OSDCoreDevice.OSDProduct = $OSDProduct
        }
        #=================================================
        # Refactor variables for deployment workflow initialization
        $OSDManufacturer = $global:OSDCoreDevice.OSDManufacturer
        $OSDModel = $global:OSDCoreDevice.OSDModel
        $OSDProduct = $global:OSDCoreDevice.OSDProduct
        #=================================================
        # Start Initialization of OSDCloud Deployment
        $initializeOSDCloudDeployParameters = @{
            EnvParameters   = $envParameters
            OSArchitecture  = $OSArchitecture
            OSDManufacturer = $OSDManufacturer
            OSDModel        = $OSDModel
            OSDProduct      = $OSDProduct
            ProfileName     = $ProfileName
            WorkflowName    = $WorkflowName
        }
        $initializeOSDCloudDeployCommand = Get-Command -Name 'Initialize-DeployOSDCloud' -ErrorAction SilentlyContinue
        if ($initializeOSDCloudDeployCommand) {
            $excludedCommonParameterNames = @(
                'Verbose',
                'Debug',
                'ErrorAction',
                'WarningAction',
                'InformationAction',
                'ErrorVariable',
                'WarningVariable',
                'InformationVariable',
                'OutVariable',
                'OutBuffer',
                'PipelineVariable',
                'WhatIf',
                'Confirm'
            )

            $initializeEligibleParameterNames = @(
                $initializeOSDCloudDeployCommand.Parameters.Keys |
                    Where-Object {
                        (-not $initializeOSDCloudDeployParameters.ContainsKey($_)) -and
                        ($_ -notin $excludedCommonParameterNames)
                    }
            )

            foreach ($parameterName in $initializeEligibleParameterNames) {
                if (-not $PSBoundParameters.ContainsKey($parameterName)) {
                    continue
                }
                $parameterValue = $PSBoundParameters[$parameterName]
                if ($null -eq $parameterValue) {
                    continue
                }
                if ($parameterValue -is [System.String] -and [string]::IsNullOrWhiteSpace($parameterValue)) {
                    continue
                }

                $initializeOSDCloudDeployParameters[$parameterName] = $parameterValue
            }
        }
        Initialize-DeployOSDCloud @initializeOSDCloudDeployParameters
        #=================================================
        # Start Deployment Workflow
        if ($CLI.IsPresent) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [INFO]Invoke-OSDCloudWorkflowTask"
            $global:OSDCloudDeploy.TimeStart = Get-Date
            $global:OSDCloudDeploy | Out-Host
            Invoke-OSDCloudWorkflowTask
        }
        else {
            # Prevents the workflow from starting unless the Start button is clicked in the GUI
            $global:OSDCloudDeploy.TimeStart = $null

            Invoke-OSDCloudWorkflowUI -WorkflowName $WorkflowName

            if ($null -ne $global:OSDCloudDeploy.TimeStart) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [INFO] Invoke-OSDCloudWorkflowTask $WorkflowName"
                $global:OSDCloudDeploy | Out-Host
                try {
                    Invoke-OSDCloudWorkflowTask
                }
                catch {
                    Write-Warning "Failed to invoke OSDCloud Workflow '$WorkflowName': $_"
                }
            }
            else {
                Write-Host -ForegroundColor DarkYellow "[$(Get-Date -format s)] [WARN] OSDCloud Workflow '$WorkflowName' was not started."
            }
        }
    }
}
