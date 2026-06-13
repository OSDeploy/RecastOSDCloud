function Deploy-OSDCloudCLI {
    <#
    .SYNOPSIS
        Starts an OSDCloud operating system deployment in CLI mode.

    .DESCRIPTION
        Initializes and runs an OSDCloud deployment workflow directly in the current
        console session without launching the graphical UX. This function is a CLI-only
        entry point and immediately invokes workflow tasks after initialization.

    .PARAMETER OperatingSystem
        Overrides the CLI workflow OS default from workflow/cli/os-amd64.json
        or workflow/cli/os-arm64.json.
        The value must exist in the workflow's OperatingSystem values list
        (for example, 'Windows 11 24H2').

    .PARAMETER OSEdition
        Overrides the CLI workflow OS edition.

    .PARAMETER OSActivation
        Overrides the CLI workflow OS activation channel.

    .PARAMETER OSLanguageCode
        Overrides the CLI workflow OS language code.

    .PARAMETER Task
        Selects the CLI workflow task by name from workflow/cli/tasks/*.json.

    .PARAMETER SkipFirmwareUpdate
        Skips firmware update download and apply steps in the workflow.

    .PARAMETER Force
        Skips confirmation prompts for destructive workflow steps that support force behavior.

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
        Deploy-OSDCloudCLI -SkipFirmwareUpdate

        Runs the default workflow and skips firmware update steps.

    .EXAMPLE
        Deploy-OSDCloudCLI -Force

        Runs the default workflow and suppresses supported confirmation prompts.

    .OUTPUTS
        System.Void

    .NOTES
        This function does not display the graphical UX. Workflow execution begins
        immediately after initialization.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]
        $SkipFirmwareUpdate,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    dynamicparam {
        $workflowRootPath = Join-Path -Path $($MyInvocation.MyCommand.Module.ModuleBase) -ChildPath 'workflow'
        $workflowPath = Join-Path -Path $workflowRootPath -ChildPath 'cli'
        $tasksPath = Join-Path -Path $workflowPath -ChildPath 'tasks'

        $osJsonFileName = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'os-arm64.json' } else { 'os-amd64.json' }
        $osJsonPath = Join-Path -Path $workflowPath -ChildPath $osJsonFileName

        $operatingSystemValues = @()
        $osActivationValues = @()
        $osLanguageCodeValues = @()
        $osEditionValues = @()
        $taskValues = @()

        if (Test-Path -Path $osJsonPath) {
            $rawJsonContent = Get-Content -Path $osJsonPath -Raw
            $jsonContent = $rawJsonContent -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
            $osSettings = ConvertFrom-Json -InputObject $jsonContent
            $operatingSystemValues = [string[]]$osSettings.OperatingSystem.values
            $osActivationValues = [string[]]$osSettings.OSActivation.values
            $osLanguageCodeValues = [string[]]$osSettings.OSLanguageCode.values
            $osEditionValues = [string[]]($osSettings.OSEdition.values | ForEach-Object { $_.Edition })
        }

        if (Test-Path -Path $tasksPath) {
            $taskJsonFiles = Get-ChildItem -Path $tasksPath -Filter '*.json' -File
            if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
                $taskValues = [string[]]($taskJsonFiles |
                    ForEach-Object { Get-Content -Path $_.FullName -Raw | ConvertFrom-Json } |
                    Where-Object { $_.arm64 -eq $true } |
                    Select-Object -ExpandProperty name)
            }
            else {
                $taskValues = [string[]]($taskJsonFiles |
                    ForEach-Object { Get-Content -Path $_.FullName -Raw | ConvertFrom-Json } |
                    Where-Object { $_.amd64 -eq $true } |
                    Select-Object -ExpandProperty name)
            }
        }

        function New-OSDCloudCliRuntimeParameter {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Name,
                [Parameter(Mandatory = $true)]
                [string[]]$ValidateSetValues
            )

            $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $parameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
            $parameterAttribute.Mandatory = $false
            $attributeCollection.Add($parameterAttribute)
            $attributeCollection.Add([System.Management.Automation.ValidateNotNullOrEmptyAttribute]::new())

            if ($ValidateSetValues.Count -gt 0) {
                $validateSetAttribute = [System.Management.Automation.ValidateSetAttribute]::new($ValidateSetValues)
                $validateSetAttribute.IgnoreCase = $true
                $attributeCollection.Add($validateSetAttribute)
            }

            return [System.Management.Automation.RuntimeDefinedParameter]::new($Name, [System.String], $attributeCollection)
        }

        $dynamicParameters = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        $dynamicParameters.Add('OperatingSystem', (New-OSDCloudCliRuntimeParameter -Name 'OperatingSystem' -ValidateSetValues $operatingSystemValues))
        $dynamicParameters.Add('OSEdition', (New-OSDCloudCliRuntimeParameter -Name 'OSEdition' -ValidateSetValues $osEditionValues))
        $dynamicParameters.Add('OSActivation', (New-OSDCloudCliRuntimeParameter -Name 'OSActivation' -ValidateSetValues $osActivationValues))
        $dynamicParameters.Add('OSLanguageCode', (New-OSDCloudCliRuntimeParameter -Name 'OSLanguageCode' -ValidateSetValues $osLanguageCodeValues))
        $dynamicParameters.Add('Task', (New-OSDCloudCliRuntimeParameter -Name 'Task' -ValidateSetValues $taskValues))

        return $dynamicParameters
    }

    begin {
        $OperatingSystem = [System.String]$PSBoundParameters['OperatingSystem']
        $OSEdition = [System.String]$PSBoundParameters['OSEdition']
        $OSActivation = [System.String]$PSBoundParameters['OSActivation']
        $OSLanguageCode = [System.String]$PSBoundParameters['OSLanguageCode']
        $Task = [System.String]$PSBoundParameters['Task']

        #=================================================
        # Initialize OSDCloudWorkflow
        $WorkflowName = 'cli'
        Initialize-OSDCloudDeploy -WorkflowName $WorkflowName

        $selectedTask = if ($PSBoundParameters.ContainsKey('Task')) { $Task } else { [System.String]$global:OSDCloudDeploy.WorkflowTaskName }

        $selectedOperatingSystem = if ($PSBoundParameters.ContainsKey('OperatingSystem')) { $OperatingSystem } else { [System.String]$global:OSDCloudDeploy.OperatingSystem }
        $selectedOSEdition = if ($PSBoundParameters.ContainsKey('OSEdition')) { $OSEdition } else { [System.String]$global:OSDCloudDeploy.OSEdition }
        $selectedOSActivation = if ($PSBoundParameters.ContainsKey('OSActivation')) { $OSActivation } else { [System.String]$global:OSDCloudDeploy.OSActivation }
        $selectedOSLanguageCode = if ($PSBoundParameters.ContainsKey('OSLanguageCode')) { $OSLanguageCode } else { [System.String]$global:OSDCloudDeploy.OSLanguageCode }

        if ($selectedOSEdition -in @('Enterprise', 'Enterprise N')) {
            if ($selectedOSActivation -ne 'Volume') {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSEdition '$selectedOSEdition' requires OSActivation 'Volume'."
            }
            $selectedOSActivation = 'Volume'
        }
        elseif ($selectedOSEdition -in @('Home', 'Home N')) {
            if ($selectedOSActivation -ne 'Retail') {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSEdition '$selectedOSEdition' requires OSActivation 'Retail'."
            }
            $selectedOSActivation = 'Retail'
        }

        $operatingSystemValues = [array]$global:OSDCloudDeploy.OperatingSystemValues
        if ($selectedOperatingSystem -notin $operatingSystemValues) {
            throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OperatingSystem '$selectedOperatingSystem' is not valid for workflow '$WorkflowName'. Valid values: $($operatingSystemValues -join ', ')"
        }

        $osActivationValues = [array]$global:OSDCloudDeploy.OSActivationValues
        if ($selectedOSActivation -notin $osActivationValues) {
            throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSActivation '$selectedOSActivation' is not valid for workflow '$WorkflowName'. Valid values: $($osActivationValues -join ', ')"
        }

        $osLanguageCodeValues = [array]$global:OSDCloudDeploy.OSLanguageCodeValues
        if ($selectedOSLanguageCode -notin $osLanguageCodeValues) {
            throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSLanguageCode '$selectedOSLanguageCode' is not valid for workflow '$WorkflowName'. Valid values: $($osLanguageCodeValues -join ', ')"
        }

        $osEditionValues = [array]$global:OSDCloudDeploy.OSEditionValues
        $selectedOSEditionObject = $osEditionValues | Where-Object { $_.Edition -eq $selectedOSEdition } | Select-Object -First 1
        if (-not $selectedOSEditionObject) {
            $validOSEditions = $osEditionValues | ForEach-Object { $_.Edition }
            throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSEdition '$selectedOSEdition' is not valid for workflow '$WorkflowName'. Valid values: $($validOSEditions -join ', ')"
        }

        $workflowTaskValues = [array]($global:OSDCloudDeploy.Flows | Select-Object -ExpandProperty Name)
        if ($selectedTask -notin $workflowTaskValues) {
            throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Task '$selectedTask' is not valid for workflow '$WorkflowName'. Valid values: $($workflowTaskValues -join ', ')"
        }

        $workflowTaskObject = $global:OSDCloudDeploy.Flows | Where-Object { $_.Name -eq $selectedTask } | Select-Object -First 1

        $operatingSystemObject = $global:DeployOSDCloudOperatingSystems |
            Where-Object { $_.OperatingSystem -eq $selectedOperatingSystem } |
            Where-Object { $_.OSActivation -eq $selectedOSActivation } |
            Where-Object { $_.OSLanguageCode -eq $selectedOSLanguageCode } |
            Select-Object -First 1

        if (-not $operatingSystemObject) {
            throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] No Operating System object found for OperatingSystem '$selectedOperatingSystem' with OSActivation '$selectedOSActivation' and OSLanguageCode '$selectedOSLanguageCode'."
        }

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OperatingSystem: $selectedOperatingSystem"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSEdition: $selectedOSEdition"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSActivation: $selectedOSActivation"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSLanguageCode: $selectedOSLanguageCode"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Task: $selectedTask"

        $global:OSDCloudDeploy.OperatingSystem = $operatingSystemObject.OperatingSystem
        $global:OSDCloudDeploy.OperatingSystemObject = $operatingSystemObject
        $global:OSDCloudDeploy.OSBuild = $operatingSystemObject.OSBuild
        $global:OSDCloudDeploy.OSBuildVersion = $operatingSystemObject.OSBuildVersion
        $global:OSDCloudDeploy.OSVersion = $operatingSystemObject.OSVersion
        $global:OSDCloudDeploy.ImageFileName = $operatingSystemObject.FileName
        $global:OSDCloudDeploy.ImageFileUrl = $operatingSystemObject.FilePath
        $global:OSDCloudDeploy.OSEdition = $selectedOSEdition
        $global:OSDCloudDeploy.OSEditionId = $selectedOSEditionObject.EditionId
        $global:OSDCloudDeploy.OSActivation = $selectedOSActivation
        $global:OSDCloudDeploy.OSLanguageCode = $selectedOSLanguageCode
        $global:OSDCloudDeploy.WorkflowTaskName = $selectedTask
        $global:OSDCloudDeploy.WorkflowTaskObject = $workflowTaskObject

        $global:OSDCloudDeploy.SkipFirmwareUpdate = $SkipFirmwareUpdate.IsPresent
        $global:OSDCloudDeploy.Force = $Force.IsPresent
        #=================================================
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask"
        $global:OSDCloudDeploy.TimeStart = Get-Date
        $global:OSDCloudDeploy | Out-Host
        Invoke-OSDCloudWorkflowTask
        #=================================================
    }
}
