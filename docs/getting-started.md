# Getting Started with OSDCloud

OSDCloud is a PowerShell module for deploying Windows from cloud-hosted
operating system and driver content. It runs in both Windows PE and standard
Windows environments.

## Requirements

| Requirement | Details |
|---|---|
| PowerShell | Windows PowerShell 5.1 or PowerShell 7+ |
| Environment | Windows or WinPE (WinPE-only cmdlets require `SystemDrive == X:`) |
| WinPE components | `WinPE-NetFX` and `WinPE-PowerShell` (for `Start-OSDCloudExplorer`) |
| Network | Internet access to Microsoft Update Catalog, PowerShell Gallery, and driver OEM sites |
| Disk space | Minimum 8 GB free on the target disk (ESD images vary in size) |
| Memory | Minimum 2 GB RAM; 6 GB or more recommended (a warning is issued below 6 GB) |

## Install

### In WinPE

```powershell
Install-Module -Name OSDCloud -SkipPublisherCheck -Force
Import-Module OSDCloud
```

### In Windows (from an elevated PowerShell session)

```powershell
Install-Module -Name OSDCloud -Scope AllUsers
Import-Module OSDCloud
```

### Check the installed version

```powershell
Get-OSDCloudModuleVersion
```

## Quick start

```powershell
# Show device hardware information
Show-OSDCloudDeviceInfo

# Launch the interactive deployment UI (default workflow)
Deploy-OSDCloud

# Run a deployment without the UI
Deploy-OSDCloud -CLI
```

## Exported cmdlets

### All environments

| Cmdlet | Alias | Description |
|---|---|---|
| `Deploy-OSDCloud` | — | Starts an OS deployment workflow (GUI or CLI mode). |
| `Get-OSDCloudModulePath` | — | Returns the module's installation directory. |
| `Get-OSDCloudModuleVersion` | — | Returns the loaded module version. |
| `Show-OSDCloudDeviceInfo` | `Show-PEStartupDeviceInfo` | Displays device hardware and environment info. |
| `Start-OSDCloudExplorer` | `OSDCloudExplorer` | Opens a WinForms file browser (useful in WinPE). |

### WinPE only (`SystemDrive == X:`)

| Cmdlet | Alias | Description |
|---|---|---|
| `Invoke-WinPEStartup` | `Invoke-OSDCloudPEStartup` | Runs the full WinPE startup workflow. |
| `Invoke-WinPEStartupManager` | — | Dispatches individual startup actions. |
| `Show-WinPEStartupDevices` | `Show-PEStartupHardware` | Shows all PnP devices in a table. |
| `Show-WinPEStartupDeviceErrors` | `Show-PEStartupErrors` | Shows PnP devices with errors. |
| `Show-WinPEStartupIpconfig` | `Show-PEStartupIpconfig` | Displays `ipconfig /all` output. |
| `Show-WinPEStartupWifi` | `Invoke-OSDCloudWifi` | Connects to Wi-Fi and waits for DHCP. |
| `Update-WinPEStartupModule` | `Use-PEStartupUpdateModule` | Updates a module from PSGallery. |

> **Note:** WinPE-only cmdlets are not loaded when OSDCloud is imported in a
> normal Windows session. Calling them outside WinPE will produce a
> "command not found" error.

## Where to go next

- [winpe-startup.md](winpe-startup.md) — detailed walkthrough of the WinPE startup sequence
- [workflows.md](workflows.md) — deployment channels and the 39-step default task
- [psoptions.md](psoptions.md) — customising default parameter values for `Invoke-WinPEStartup`
- [../OSDCloud/docs/Deploy-OSDCloud.md](../OSDCloud/docs/Deploy-OSDCloud.md) — full reference for `Deploy-OSDCloud`
- [../OSDCloud/docs/Invoke-WinPEStartup.md](../OSDCloud/docs/Invoke-WinPEStartup.md) — full reference for `Invoke-WinPEStartup`
