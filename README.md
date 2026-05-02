# OSDCloud

[![PSGallery Version](https://img.shields.io/powershellgallery/v/OSDCloud.svg?style=flat&logo=powershell&label=PSGallery%20Version)](https://www.powershellgallery.com/packages/OSDCloud) [![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/OSDCloud.svg?style=flat&logo=powershell&label=PSGallery%20Downloads)](https://www.powershellgallery.com/packages/OSDCloud) [![PowerShell](https://img.shields.io/badge/PowerShell-5.1-blue?style=flat&logo=powershell)](https://www.powershellgallery.com/packages/OSDCloud)

OSDCloud is a PowerShell module for deploying Windows with cloud-hosted operating system and driver content.

## Overview

- Focused on Windows deployment workflows driven by PowerShell.
- Supports WinPE startup helpers and deployment UX options.
- Provides cmdlets for device info, Wi-Fi setup, and module updates in PE.

## Requirements

- Windows PowerShell 5.1
- Windows or WinPE environment (for PE-specific cmdlets)

## Install

```powershell
# In WinPE
Install-Module -Name OSDCloud -SkipPublisherCheck -Force

# In Windows (elevated session)
Install-Module -Name OSDCloud -Scope AllUsers
```

## Quick start

```powershell
Import-Module OSDCloud

# Show device hardware information
Show-OSDCloudDeviceInfo

# Launch the interactive deployment experience
Deploy-OSDCloud
```

## Commands

**All environments**

| Cmdlet | Description |
|---|---|
| `Deploy-OSDCloud` | Starts an OS deployment workflow (GUI or CLI mode). |
| `Get-OSDCloudModulePath` | Returns the module installation directory. |
| `Get-OSDCloudModuleVersion` | Returns the loaded module version. |
| `Show-OSDCloudDeviceInfo` | Displays device hardware and environment information. |
| `Start-OSDCloudExplorer` | Opens a WinForms file browser (useful in WinPE/WinRE). |

**WinPE only** (`SystemDrive == X:`)

| Cmdlet | Alias | Description |
|---|---|---|
| `Invoke-WinPEStartup` | `Invoke-OSDCloudPEStartup` | Runs the full WinPE startup workflow. |
| `Invoke-WinPEStartupManager` | — | Dispatches individual startup actions. |
| `Show-WinPEStartupDevices` | `Show-PEStartupHardware` | Shows all PnP devices. |
| `Show-WinPEStartupDeviceErrors` | `Show-PEStartupErrors` | Shows PnP devices with errors. |
| `Show-WinPEStartupIpconfig` | `Show-PEStartupIpconfig` | Displays `ipconfig /all`. |
| `Show-WinPEStartupWifi` | `Invoke-OSDCloudWifi` | Connects to Wi-Fi and waits for DHCP. |
| `Update-WinPEStartupModule` | `Use-PEStartupUpdateModule` | Updates a module from PSGallery. |

## Documentation

### Guides

| Guide | Description |
|---|---|
| [docs/getting-started.md](docs/getting-started.md) | Installation, quick start, and cmdlet overview. |
| [docs/winpe-startup.md](docs/winpe-startup.md) | WinPE startup sequence, script hooks, and USB profiles. |
| [docs/psoptions.md](docs/psoptions.md) | Two-layer PSDefaultParameterValues system and full key reference. |
| [docs/workflows.md](docs/workflows.md) | Deployment channels and the 39-step default task. |

### Function reference

| Reference page | Function |
|---|---|
| [docs/Deploy-OSDCloud.md](OSDCloud/docs/Deploy-OSDCloud.md) | `Deploy-OSDCloud` |
| [docs/Get-OSDCloudModulePath.md](OSDCloud/docs/Get-OSDCloudModulePath.md) | `Get-OSDCloudModulePath` |
| [docs/Get-OSDCloudModuleVersion.md](OSDCloud/docs/Get-OSDCloudModuleVersion.md) | `Get-OSDCloudModuleVersion` |
| [docs/Show-OSDCloudDeviceInfo.md](OSDCloud/docs/Show-OSDCloudDeviceInfo.md) | `Show-OSDCloudDeviceInfo` |
| [docs/Start-OSDCloudExplorer.md](OSDCloud/docs/Start-OSDCloudExplorer.md) | `Start-OSDCloudExplorer` |
| [docs/Invoke-WinPEStartup.md](OSDCloud/docs/Invoke-WinPEStartup.md) | `Invoke-WinPEStartup` |
| [docs/Invoke-WinPEStartupManager.md](OSDCloud/docs/Invoke-WinPEStartupManager.md) | `Invoke-WinPEStartupManager` |
| [docs/Show-WinPEStartupDevices.md](OSDCloud/docs/Show-WinPEStartupDevices.md) | `Show-WinPEStartupDevices` |
| [docs/Show-WinPEStartupDeviceErrors.md](OSDCloud/docs/Show-WinPEStartupDeviceErrors.md) | `Show-WinPEStartupDeviceErrors` |
| [docs/Show-WinPEStartupIpconfig.md](OSDCloud/docs/Show-WinPEStartupIpconfig.md) | `Show-WinPEStartupIpconfig` |
| [docs/Show-WinPEStartupWifi.md](OSDCloud/docs/Show-WinPEStartupWifi.md) | `Show-WinPEStartupWifi` |
| [docs/Update-WinPEStartupModule.md](OSDCloud/docs/Update-WinPEStartupModule.md) | `Update-WinPEStartupModule` |

### External links

- [PowerShell Gallery — OSDCloud](https://www.powershellgallery.com/packages/OSDCloud)
- [GitHub Issues](https://github.com/OSDeploy/OSDCloud/issues)

## Release notes

See [CHANGELOG.md](CHANGELOG.md) for module release history.

## Privacy policy

OSDCloud sends anonymous deployment analytics during workflow execution. See [PRIVACY.md](PRIVACY.md) for details on what data is collected and how to opt out.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

See [LICENSE](LICENSE).
