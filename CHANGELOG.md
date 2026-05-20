# Changelog

All notable changes to this project will be documented in this file.

## 26.5.20.1 - May 20, 2026

### Added

- `Get-OSDCloudCatalogSurface`: when `$global:OSDCloudDevice.OSDProduct` is set, live `UpdatePage` network requests are limited to the single matching catalog entry; all other entries return base JSON values, eliminating the full catalog scan during deployment.

### Changed

- Module version bumped to `26.5.20.1`.
- Microsoft Surface driver pack catalog updated with latest MSI versions for 18 models (all bumped to `26.04x` builds).

## 26.5.19.1 - May 19, 2026

### Added

- OS catalog updated with Windows 11 25H2 build 26200.8457 (compiled 2026-05-07).

### Changed

- Module version bumped to `26.5.19.1`.
- Dell driver pack catalog updated to version `2026.05.04` (dated 2026-05-15).
- HP driver pack catalog updated (DateReleased `2026-05-19`).
- Lenovo driver pack catalog refreshed from upstream `catalogv2.xml`.
- GitHub Actions catalog-update workflows (`update-catalog-dell.yaml`, `update-catalog-hp.yaml`, `update-catalog-lenovo.yaml`) changed to on-demand (`workflow_dispatch`) only — weekly cron schedule removed.
- `docs/workflows.md` simplified to only describe the `default` deployment channel.
- `publish-module.yaml` corrected to check out the current repository without a hardcoded `path`, `repository`, or `ref`; publish step switched to `shell: pwsh`; permissions tightened to `contents: read`.

## 26.4.27.1 - April 27, 2026

### Added

- Reference documentation for all 12 exported functions in `OSDCloud/docs/`:
  - New pages: `Invoke-WinPEStartup.md`, `Invoke-WinPEStartupManager.md`,
    `Show-WinPEStartupDevices.md`, `Show-WinPEStartupDeviceErrors.md`,
    `Show-WinPEStartupIpconfig.md`, `Show-WinPEStartupWifi.md`,
    `Update-WinPEStartupModule.md`
  - Updated existing pages to fill in blank `ProgressAction` descriptions,
    add `INPUTS`/`OUTPUTS`/`NOTES` sections, and cross-link related pages.
- Conceptual guides in `docs/`:
  - `getting-started.md` — installation, quick start, and cmdlet overview.
  - `winpe-startup.md` — WinPE startup sequence, script hooks, USB profiles,
    and `InvokeXxxCommand` behaviour.
  - `psoptions.md` — two-layer `PSDefaultParameterValues` system with full
    key reference table and override examples.
  - `workflows.md` — deployment channels, the 39-step default task (grouped
    by phase), and skip-flag semantics.

### Changed

- `README.md` updated with a complete command table (all 12 exported cmdlets
  with aliases), a Guides section, and a Function reference table linking to
  all docs pages.
- `CONTRIBUTING.md` expanded with PowerShell coding conventions, WinPE guard
  rules, documentation requirements, workflow/task contribution guide,
  catalog update pointer, Pester testing guidance, and a PR checklist.
- `PRIVACY.md` updated with effective date, confirmed SHA-256 hashing
  algorithm for the device identifier, and clarified external service
  interactions.

## 26.4.17.1 - April 17, 2026

### Changed

- Updated OSDCloud OS catalog with Windows 11 25H2 build 26200.8246.

## 26.4.7.1 - April 7, 2026

### Added

- `Show-OSDCloudDeviceInfo` function for enhanced device information display (#59)
- GitHub Copilot instructions for catalog updates, workflow tasks, and driver pack updates (#58)

### Changed

- Updated Microsoft Surface device driver pack catalog versions and release dates (#57)
- Enhanced device info display and updated logging messages across core functions (#59)
- Refactored `Initialize-OSDCloudDevice` with improved device info collection (#59)
- Updated Dell driver pack catalog (DriverPackManifest version 2026.03.04)
- Updated HP driver pack catalog (HPClientDriverPackCatalog DateReleased 2026-04-06)
- Updated Lenovo driver pack catalog (catalogv2.xml version 1.0, 2026-04-07)

## 26.3.27.1 - March 27, 2026

### Changed

- Updated Dell driver pack catalog (DriverPackCatalog v2026.03.02, releaseID F3GCP)
- Updated HP driver pack catalog (HPClientDriverPackCatalog v2.00 A 1)
- Updated Lenovo driver pack catalog (catalogv2.xml v1.0)

## 26.3.23.1 - March 23, 2026

### Added

- Dev-device workflow with full WPF application structure and UI (#53)
- Enhanced clipboard functionality in MainWindow UI (#53)

### Changed

- Updated Microsoft driver pack catalog (#53)
- Changed verbose logging to host output for time synchronization (#50)
- Refactored MainWindow code across default, dev-alpha, dev-beta, and insiders workflows (#53)

## 26.3.12.1 - March 12, 2026

### Added

- Updated OSDCloud OS catalog with Windows 11 25H2 build 26200.8037.

## 26.3.4.1 - March 4, 2026

### Added

- Panasonic driver pack catalog support (#45)
- `Sync-InternetDateTime` function for time synchronization (#45)
- `step-Add-WindowsDriver-Disk` and `step-Export-WindowsDriver-OemWinPE` driver steps (#45)

### Changed

- Enhanced download process with validation and error handling (#46)
- Updated log copying mechanism for improved efficiency (#47)
- Renamed driver export steps to follow consistent `step-Add-WindowsDriver-*` and `step-Save-WindowsDriver-*` naming convention (#45)
- Enhanced logging across multiple workflow steps (#45)
- Updated HP, Lenovo, and default driver pack catalogs (#44)
- Reorganized WiFi and network connection modules (#44)
- Improved PE startup functions and UI handling in MainWindow (#44)

### Removed

- Deprecated `step-drivers-recast-winos.ps1` and `step-drivers-recast-winpe.ps1` (#45)
- Removed `Invoke-PEStartupOSK.ps1` (#44)

## 26.2.16.1 - February 16, 2026

### Added

- Windows 11 25H2 February 2026 OS catalog release (#39)
- OSDCloud by Recast branding (#37)
- `Invoke-OSDCloudDownloadFile` function for centralized download handling (#33)
- Curl availability check for downloads (#34)

### Changed

- Updated OSDCloud workflows and task names (#35, #34)
- Improved UI with adjusted column widths in MainWindow layout (#31)
- Updated driver pack management for Windows 11 (#43)
- Updated OS configurations (#38)

### Removed

- Deprecated tasks and unused workflow code (#38, #35)
- Redundant code changes sections (#30)
