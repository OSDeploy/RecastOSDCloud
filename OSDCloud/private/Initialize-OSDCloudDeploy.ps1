function Initialize-OSDCloudDeploy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [System.String]
        $WorkflowName = 'default',

        [Parameter(Mandatory = $false)]
        [System.Collections.IDictionary]
        $EnvParameters,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ProfileName = 'default'
    )
    $ErrorActionPreference = 'Stop'
    #=================================================
    # Get module details
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] $ModuleVersion"
    #=================================================
    # OSDCloud Env override layer
    # Assemble $global:OSDCloudEnv early so initial property resolution can consume
    # values from the selected profile and parameter overrides.
    if (Get-Command -Name 'Initialize-OSDCloudEnv' -ErrorAction SilentlyContinue) {
        Initialize-OSDCloudEnv -Parameters $EnvParameters -ProfileName $ProfileName | Out-Null
    }
    #=================================================
    # Dependencies
    # Make sure curl.exe is present and throw if not
    if (-not (Get-Command -Name 'curl.exe' -ErrorAction SilentlyContinue)) {
        throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDCloud requires 'curl.exe' which is not available on this system. Please ensure curl.exe is available in the system PATH."
    }
    #=================================================
    # Get-DeploymentDiskObject
    $DeploymentDiskObject = Get-DeploymentDiskObject

    # Make sure Get-DeploymentDiskObject returns a single object
    if (-not $DeploymentDiskObject) {
        throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDCloud requires at least one Local Disk, but no compatible Local Disk was found."
    }
    # Warn if multiple disks found and inform which disk will be used
    # Include the Friendly Name of the disk for clarity
    # Include the size in GB for clarity
    if (@($DeploymentDiskObject).Count -gt 1) {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Multiple Local Disks were found. OSDCloud will default to DiskNumber: $($DeploymentDiskObject[0].DiskNumber)"
        $DeploymentDiskObject | ForEach-Object {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] DiskNumber: $($_.DiskNumber), FriendlyName: $($_.FriendlyName), Size(GB): $([math]::Round($_.Size / 1GB, 2))"
        }
    }
    # Limit to the first disk found
    $DeploymentDiskObject = $DeploymentDiskObject | Select-Object -First 1
    #=================================================
    # OSDCoreDevice
    <#
        PS C:\Users\david> $OSDCoreDevice
        Name                           Value
        ----                           -----
        OSDManufacturer                HP
        OSDModel                       HP Z2 Mini G9 Workstation Desktop PC
        OSDProduct                     895E
        ComputerName                   OSDMAIN
        BaseBoardProduct               895E
        BiosReleaseDate                11/02/2025 18:00:00
        BiosVersion                    U50 Ver. 03.05.02
        ComputerManufacturer           HP
        ComputerModel                  HP Z2 Mini G9 Workstation Desktop PC
        ComputerSystemFamily           103C_53335X HP Workstation
        ComputerSystemProduct          SBKPF,DWKSBLF,SBKPFV3
        ComputerSystemSKU              B40ZBUP#ABA
        ComputerSystemType             Small Form Factor
        HardwareHash
        IsAutopilotSpec                True
        IsDesktop                      False
        IsLaptop                       False
        IsOnBattery                    False
        IsServer                       False
        IsSFF                          True
        IsTablet                       False
        IsTpmSpec                      True
        IsVM                           False
        IsUEFI                         True
        KeyboardLayout                 00000409
        KeyboardName                   Enhanced (101- or 102-key)
        NetGateways                    {192.168.0.1, $null}
        NetIPAddress                   {192.168.0.121, fe80::81d7:1db5:c6cc:e822, fd1a:2b60:6c6d:4ec6:3111:5f06:51a4:c72e, fd1a:2b60:6c6d:4ec6:1236:ad56:5fe8:9d11...}
        NetMacAddress                  {64:4B:F0:39:11:3A, 10:4A:26:03:04:16}
        OSArchitecture                 64-bit
        OSVersion                      10.0.26200
        ProcessorArchitecture          AMD64
        SerialNumber                   MXL4414JQT
        SystemFirmwareHardwareId       EF647623-90B4-44BC-8866-D6FB7F29AB46
        TimeZone                       Central Standard Time
        TotalPhysicalMemoryGB          128
        TpmIsActivated                 True
        TpmIsEnabled                   True
        TpmIsOwned                     True
        TpmManufacturerIdTxt           NTC
        TpmManufacturerVersion         7.2.3.1
        TpmSpecVersion                 2.0, 0, 1.59
        UUID                           048A2C6B-A1D9-488C-8BF0-18D0F9A82D91
    #>
    if (-not ($global:OSDCoreDevice)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Initialize OSDCloud Device"
        Initialize-OSDCoreDevice
    }
    #=================================================
    # OSDCloudWorkflowTasks
    # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Initialize OSDCloud Tasks"
    # If $WorkflowName is not default, display a message that this Workflow is for Beta or Testing purposes only
    if ($WorkflowName -ne 'default') {
        Write-Warning "[$(Get-Date -format s)] The workflow '$WorkflowName' is for Beta testing purposes only."
    }

    Initialize-OSDCloudWorkflowTasks -WorkflowName $WorkflowName
    # Make sure at least one workflow task is defined
    if (-not $global:OSDCloudWorkflowTasks) {
        throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Initialize-OSDCloudDeploy requires at least one valid workflow task. Please check your OSDCloud Workflow Tasks."
    }
    # Update WorkflowTaskObject and WorkflowTaskName in the Init global variable
    $WorkflowTaskObject = $global:OSDCloudWorkflowTasks | Select-Object -First 1
    $WorkflowTaskName = $WorkflowTaskObject.name
    #=================================================
    # OSDCloudWorkflowSettingsUser
    #TODO : Remove dependency on User Settings for future releases
    # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Initialize OSDCloud Settings User"
    # Initialize-OSDCloudWorkflowSettingsUser -WorkflowName $WorkflowName
    #=================================================
    # OSDCloud Operating Systems
    # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Get OSDCloud OperatingSystems"

    # Limit to matching Processor Architecture
    $ProcessorArchitecture = $global:OSDCoreDevice.ProcessorArchitecture
    $global:DeployOSDCloudOperatingSystems = Get-OSDCloudCoreOperatingSystems | Where-Object { $_.OSArchitecture -match "$ProcessorArchitecture" }

    # Need to fail if no OS found for Architecture
    if (-not $global:DeployOSDCloudOperatingSystems) {
        throw "No Operating Systems found for Architecture: $ProcessorArchitecture. Please check your OSDCloud OperatingSystems."
    }
    #=================================================
    # OSDCloudWorkflowSettingsOS
    # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Initialize OSDCloud Workflow Settings OS"
    Initialize-OSDCloudWorkflowSettingsOS -WorkflowName $WorkflowName
    #=================================================
    # Set initial Operating System
    <#
        Id              : Windows 11 25H2 amd64 Retail en-gb 26200.7462
        OperatingSystem : Windows 11 25H2
        OSName          : Windows 11
        OSVersion       : 25H2
        OSArchitecture  : amd64
        OSActivation    : Retail
        LanguageCode    : en-gb
        Language        : English (United Kingdom)
        OSBuild         : 26200
        OSBuildVersion  : 26200.7462
        Size            : 5626355066
        Sha1            :
        Sha256          : 566a518dc46ba5ea401381810751a8abcfe7d012b2f81c9709b787358c606926
        FileName        : 26200.7462.251207-0044.25h2_ge_release_svc_refresh_CLIENTCONSUMER_RET_x64FRE_en-gb.esd
        FilePath        : http://dl.delivery.mp.microsoft.com/filestreamingservice/files/79a3f5e0-d04d-4689-a5d4-3ea35f8b189a/26200.7462.251207-0044.25h2_ge_release_svc_refresh_CLIENTCONSUMER_RET_x64FRE_en-gb.esd
    #>
    $OperatingSystem = $global:OSDCloudWorkflowSettingsOS.OperatingSystem.default
    $OperatingSystemValues = [array]$global:OSDCloudWorkflowSettingsOS.OperatingSystem.values
    $OSActivation = $global:OSDCloudWorkflowSettingsOS.OSActivation.default
    $OSActivationValues = [array]$global:OSDCloudWorkflowSettingsOS.OSActivation.values
    $OSArchitecture = $ProcessorArchitecture
    $OSEdition = $global:OSDCloudWorkflowSettingsOS.OSEdition.default
    $OSEditionValues = [array]$global:OSDCloudWorkflowSettingsOS.OSEdition.values
    $OSEditionId = ($OSEditionValues | Where-Object { $_.Edition -eq $OSEdition }).EditionId
    $OSLanguageCode = $global:OSDCloudWorkflowSettingsOS.OSLanguageCode.default
    $OSLanguageCodeValues = [array]$global:OSDCloudWorkflowSettingsOS.OSLanguageCode.values
    $OSVersion = ($global:OSDCloudWorkflowSettingsOS.OperatingSystem.default -split ' ')[2]
    #=================================================
    #   OSDCloudEnv
    #=================================================
    # Use OSDCloudEnv to override these properties:
    #   OperatingSystem, OSEdition, OSActivation, OSLanguageCode
    if ($global:OSDCloudEnv) {
        if ($global:OSDCloudEnv.OperatingSystem) {
            $OperatingSystem = $global:OSDCloudEnv.OperatingSystem
        }
        if ($global:OSDCloudEnv.OSEdition) {
            $OSEdition = $global:OSDCloudEnv.OSEdition
            $OSEditionId = ($OSEditionValues | Where-Object { $_.Edition -eq $OSEdition }).EditionId
        }
        if ($global:OSDCloudEnv.OSActivation) {
            $OSActivation = $global:OSDCloudEnv.OSActivation
        }
        if ($global:OSDCloudEnv.OSLanguageCode) {
            $OSLanguageCode = $global:OSDCloudEnv.OSLanguageCode
        }
    }
    #=================================================
    # OperatingSystemObject
    $OperatingSystemObject = $global:DeployOSDCloudOperatingSystems | Where-Object { $_.OperatingSystem -match $OperatingSystem } | Where-Object { $_.OSActivation -eq $OSActivation } | Where-Object { $_.OSLanguageCode -eq $OSLanguageCode }
    if (-not $OperatingSystemObject) {
        throw "No Operating System found for OperatingSystem: $OperatingSystem, OSActivation: $OSActivation, OSLanguageCode: $OSLanguageCode. Please check your OSDCloud OperatingSystems."
    }
    $OSName = $OperatingSystemObject.OSName
    $OSBuild = $OperatingSystemObject.OSBuild
    $OSBuildVersion = $OperatingSystemObject.OSBuildVersion
    $ImageFileName = $OperatingSystemObject.FileName
    $ImageFileUrl = $OperatingSystemObject.FilePath
    #=================================================
    # DriverPacks
    $OSDManufacturer = $global:OSDCoreDevice.OSDManufacturer
    $OSDModel = $global:OSDCoreDevice.OSDModel
    $OSDProduct = $global:OSDCoreDevice.OSDProduct
    $DriverPackValues = Get-OSDCloudCoreDriverPacks
    $DriverPackObject = $DriverPackValues | Where-Object { $_.SystemId -match $OSDProduct } | Select-Object -First 1

    if ($DriverPackObject) {
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] OSDManufacturer: $OSDManufacturer"
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] OSDModel: $OSDModel"
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] OSDProduct: $OSDProduct"
        $DriverPackName = $DriverPackObject.Name
        $DriverPackUrl = $DriverPackObject.Url
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] DriverPack: $DriverPackName"
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] DriverPack Url: $DriverPackUrl"
    } else {
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] OSDManufacturer: $OSDManufacturer"
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] OSDModel: $OSDModel"
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] OSDProduct: $OSDProduct"
    }
    #=================================================
    # Main
    $global:OSDCloudDeploy = $null
    $global:OSDCloudDeploy = [ordered]@{
        DeploymentDiskObject      = $DeploymentDiskObject
        DriverFolderName          = $null
        DriverFolderNames         = @()
        DriverFolderPath          = $null
        DriverFolderPaths         = @()
        DriverFolderSelections    = @()
        DriverPackName            = $DriverPackName
        DriverPackObject          = $DriverPackObject
        DriverPackValues          = [array]$DriverPackValues
        Flows                     = [array]$global:OSDCloudWorkflowTasks
        Function                  = $($MyInvocation.MyCommand.Name)
        ImageFileName             = $ImageFileName
        ImageFileUrl              = $ImageFileUrl
        LaunchMethod              = 'OSDCloudWorkflow'
        Module                    = $($MyInvocation.MyCommand.Module.Name)
        OperatingSystem           = $OperatingSystem
        OperatingSystemObject     = $OperatingSystemObject
        OperatingSystemValues     = $OperatingSystemValues
        OSActivation              = $OSActivation
        OSActivationValues        = $OSActivationValues
        OSArchitecture            = $OSArchitecture
        OSBuild                   = $OSBuild
        OSBuildVersion            = $OSBuildVersion
        OSEdition                 = $OSEdition
        OSEditionId               = $OSEditionId
        OSEditionValues           = $OSEditionValues
        OSLanguageCode            = $OSLanguageCode
        OSLanguageCodeValues      = $OSLanguageCodeValues
        OSVersion                 = $OSVersion
        TimeStart                 = $null
        WorkflowName              = $WorkflowName
        WorkflowTaskName          = $WorkflowTaskName
        WorkflowTaskObject        = $WorkflowTaskObject
    }
    #=================================================
    # OSDCloud Env override layer
    # Apply the pre-assembled overrides onto $global:OSDCloudDeploy so they take effect
    # everywhere.
    if (Get-Command -Name 'Set-OSDCloudEnvOverride' -ErrorAction SilentlyContinue) {
        Set-OSDCloudEnvOverride -Target $global:OSDCloudDeploy -ResolveOperatingSystem -AddMissingKeys
    }
    #=================================================
}
