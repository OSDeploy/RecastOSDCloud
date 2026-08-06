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
        $ProfileName = 'default',

        [Parameter(Mandatory = $false, HelpMessage = 'Optional manufacturer override used for driver pack selection.')]
        [System.String]
        $OSDManufacturer,

        [Parameter(Mandatory = $false, HelpMessage = 'Optional model override used for driver pack selection.')]
        [System.String]
        $OSDModel,

        [Parameter(Mandatory = $false, HelpMessage = 'Optional product/system ID override used for driver pack selection.')]
        [System.String]
        $OSDProduct,

        [Parameter(Mandatory = $false, HelpMessage = 'Operating system architecture for deployment selection.')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('amd64','arm64')]
        [System.String]
        $OSArchitecture = $env:PROCESSOR_ARCHITECTURE
    )
    $ErrorActionPreference = 'Stop'
    #=================================================
    # Get module details
    # $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)]"
    #=================================================
    # OSDCloud Env override layer
    # Assemble $global:OSDCloudEnv early so initial property resolution can consume
    # values from the selected profile and parameter overrides.
    <#
    if (Get-Command -Name 'Initialize-OSDCloudEnv' -ErrorAction SilentlyContinue) {
        Initialize-OSDCloudEnv -Parameters $EnvParameters -ProfileName $ProfileName | Out-Null
    }
    #>
    #=================================================
    # Dependencies
    # Make sure curl.exe is present and throw if not
    if (-not (Get-Command -Name 'curl.exe' -ErrorAction SilentlyContinue)) {
        throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDCloud requires 'curl.exe' which is not available on this system. Please ensure curl.exe is available in the system PATH."
    }
    #=================================================
    # Initialize Architecture
    # Resolve the effective architecture once and normalize aliases.
    $processorArchitecture = if (-not [string]::IsNullOrWhiteSpace($OSArchitecture)) {
        $OSArchitecture
    }
    elseif (-not [string]::IsNullOrWhiteSpace($global:OSDCoreDevice.ProcessorArchitecture)) {
        $global:OSDCoreDevice.ProcessorArchitecture
    }
    else {
        $env:PROCESSOR_ARCHITECTURE
    }

    switch -Regex ($processorArchitecture) {
        '^(amd64|x64)$' { $processorArchitecture = 'amd64'; break }
        '^arm64$' { $processorArchitecture = 'arm64'; break }
        default {
            throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unsupported processor architecture '$processorArchitecture'. Expected amd64 or arm64."
        }
    }
    # Keep the function parameter aligned to the effective value used downstream.
    $OSArchitecture = $processorArchitecture
    #=================================================
    # OSDCoreDevice
    if (-not ($global:OSDCoreDevice)) {
        Initialize-OSDCoreDevice
    }
    #=================================================
    # OSDCoreCache
    Initialize-OSDCoreCache
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
    # OSDCoreDriverPacks
    Initialize-ModuleCoreDriverPacks -OSDManufacturer $OSDManufacturer
    if ($global:ModuleCoreDriverPacks) {
        $global:OSDCoreDriverPackCloudObject = $global:ModuleCoreDriverPacks | Where-Object { $_.SystemId -match $OSDProduct } | Select-Object -First 1
    }

    if ($global:OSDCoreDriverPackCloudObject) {
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] OSDManufacturer: $OSDManufacturer"
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] OSDModel: $OSDModel"
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] OSDProduct: $OSDProduct"
        $DriverPackName = $global:OSDCoreDriverPackCloudObject.Name
        $DriverPackUrl = $global:OSDCoreDriverPackCloudObject.Url
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] DriverPack: $DriverPackName"
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] DriverPack Url: $DriverPackUrl"
    } else {
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] OSDManufacturer: $OSDManufacturer"
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] OSDModel: $OSDModel"
        Write-Host -ForegroundColor Gray "[$(Get-Date -format s)] OSDProduct: $OSDProduct"
    }

    if ($global:OSDCoreDriverPackCloudObject) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Verifying OSDCoreDriverPackCloudObject."
        $OSDCoreDriverPackCloudObjectUrlReachable = Test-OSDCoreDriverPackCloudObject -DriverPackCloudObject $global:OSDCoreDriverPackCloudObject
        if ($OSDCoreDriverPackCloudObjectUrlReachable) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DriverPack URL is reachable. OK."
        }
        else {
            Write-Host -ForegroundColor DarkYellow "[$(Get-Date -format s)] DriverPack URL is not reachable."
        }

        # Driver pack catalogs use either HashMD5 or MD5Hash depending on the source.
        $expectedDriverPackHashMD5 = $null
        if ($global:OSDCoreDriverPackCloudObject.PSObject.Properties.Match('HashMD5').Count -gt 0) {
            $expectedDriverPackHashMD5 = [string]$global:OSDCoreDriverPackCloudObject.HashMD5
        }
        elseif ($global:OSDCoreDriverPackCloudObject.PSObject.Properties.Match('MD5Hash').Count -gt 0) {
            $expectedDriverPackHashMD5 = [string]$global:OSDCoreDriverPackCloudObject.MD5Hash
        }

        # Check whether the selected driver pack is already present in the cache inventory.
        $OSDCoreDriverPackCacheObject = Get-OSDCoreDriverPackCacheObject -DriverPackCloudObject $global:OSDCoreDriverPackCloudObject
        if ($OSDCoreDriverPackCacheObject) {
            # Verify cached driver pack integrity when the catalog includes an MD5 hash.
            if (-not [string]::IsNullOrWhiteSpace($expectedDriverPackHashMD5)) {
                $actualDriverPackHashMD5 = (Get-FileHash -Path $OSDCoreDriverPackCacheObject.FullName -Algorithm MD5 -ErrorAction Stop).Hash
                if ($actualDriverPackHashMD5 -ne $expectedDriverPackHashMD5.Trim()) {
                    throw "[$(Get-Date -format s)] DriverPack MD5 hash mismatch for $($OSDCoreDriverPackCacheObject.FullName). Expected $($expectedDriverPackHashMD5.Trim()), found $actualDriverPackHashMD5."
                }
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DriverPack cached file MD5 hash verified. OK."
            }
            else {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DriverPack cached file hash was not verified because no MD5 hash property was available."

            }
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DriverPack is ready at $($OSDCoreDriverPackCacheObject.FullName)"
        }
        else {
            Write-Host -ForegroundColor DarkYellow "[$(Get-Date -format s)] DriverPack is not available on a USB Drive."
            $OSDCoreDriverPackCacheObject = $null
        }
        # Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] OSDCoreDriverPackCloudObject"
        $global:OSDCoreDriverPackCloudObject | Out-Host
    }
    else {
        Write-Host -ForegroundColor DarkYellow "[$(Get-Date -format s)] OSDCoreDriverPackCloudObject is not set."
        Write-Host -ForegroundColor DarkYellow "[$(Get-Date -format s)] OSDCloud will not apply a DriverPack for this device or on this network."
        $OSDCoreDriverPackCacheObject = $null
    }
    #=================================================
    # ModuleCoreOperatingSystems
    <#
    Initialize-ModuleCoreOperatingSystems

    if (-not ($global:ModuleCoreOperatingSystems)) {
        throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to load Module Core Operating Systems."
    }
    #>
    #=================================================
    # OSDCoreOperatingSystems
    # Select the provider that exists in the current module context.
    $ModuleName = $($MyInvocation.MyCommand.Module.Name)
    if ($ModuleName -eq 'OSD') {
        $global:OSDCoreOperatingSystems = Get-OSDCoreOperatingSystems |
            Where-Object { $_.Architecture -match "$OSArchitecture" }
    }
    elseif ($ModuleName -eq 'OSDCloud') {
        $global:OSDCoreOperatingSystems = Get-OSDCloudCoreOperatingSystems |
            Where-Object { $_.OSArchitecture -match "$OSArchitecture" }
    }
    else {
        throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to load core operating systems provider command."
    }
    $null = Set-OSDCoreOperatingSystemCloudObject -OSArchitecture $OSArchitecture
    Break
    #=================================================
    # OSDCloudWorkflowTasks
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
    # OSDCloud Operating Systems
    # Always resolve catalog entries for the effective architecture value.
    <#
    $global:DeployOSDCloudOperatingSystems = Get-OSDCloudCoreOperatingSystems | Where-Object { $_.OSArchitecture -match "$processorArchitecture" }

    # Validate that the OS catalog was preloaded for this architecture.
    if (-not $global:DeployOSDCloudOperatingSystems) {
        throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to load OSDCloud Operating Systems."
    }
    #>
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
    $OSArchitecture = $processorArchitecture
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
        DriverPackObject          = $global:OSDCoreDriverPackCloudObject
        DriverPackValues          = [array]$global:ModuleCoreDriverPacks
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
