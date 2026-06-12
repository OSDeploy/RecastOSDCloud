# Build a WinPE Boot Image

## When to use this

Build a new boot image when:

- You are setting up OSDCloud for the first time.
- You need a new boot image for a different architecture (amd64 vs arm64).
- You want updated WinPE drivers, language packs, or a newer WinRE/ADK source.
- You added scripts or apps to `%ProgramData%\OSDeployCore\OSDRepo\` that should be in WinPE.

Rebuild **does not** automatically happen when OSDCloud publishes a new module
version — the module is downloaded at WinPE startup time, not baked in.

## Why a separate module

OSDCloud runs *inside* WinPE but doesn't build the boot image. Boot image
creation requires DISM, the Windows ADK, and Administrator on a full Windows
session — none of which are available in WinPE. That work lives in the
[**OSDeploy**](https://www.powershellgallery.com/packages/OSDeploy) module.

## Prerequisites

- Windows 11 25H2 or newer (build 26100+).
- PowerShell 7.6+ running as Administrator.
- Windows ADK installed.
- The OSDeploy module installed: `Install-Module OSDeploy -SkipPublisherCheck -Force`.

For a full prerequisite walkthrough see the OSDeploy docs:
[`../../RecastOSDeploy/docs/Build-OSDeployBoot.md`](../../RecastOSDeploy/docs/Build-OSDeployBoot.md).

## How to build

### 1. Import a Windows source (once)

```powershell
Import-OSDeployCoreOS
```

Pick a Windows 11 ISO when prompted. This extracts a WinRE source used as
the WinPE baseline. Skip this step if you plan to use `-UseAdkWinPE` instead.

### 2. (Optional) Refresh WinPE drivers

```powershell
Update-OSDeployCoreDrivers
```

Downloads current WinPE network/storage drivers into
`%ProgramData%\OSDeployCore\OSDRepo\winpe-drivers\`. They are injected
automatically on the next build.

### 3. Build the image

```powershell
# amd64 from imported WinRE
Build-OSDeployBoot -Name 'OSDCloud-amd64'

# arm64 from the ADK
Build-OSDeployBoot -Name 'OSDCloud-arm64' -UseAdkWinPE -Architecture arm64
```

Output lands in `%ProgramData%\OSDeployCore\boot\<Name>-<timestamp>\`:

| File / folder | Use |
|---|---|
| `bootmedia\` | Files to copy to a USB or PXE share |
| `bootmedia.iso` | Bootable ISO (UEFI CA 2011) |
| `bootmedia_ca2023.iso` | Bootable ISO using the UEFI CA 2023 boot manager (for Secure Boot policies that require it) |

### 4. Verify OSDCloud is in the image

OSDCloud is **not** pre-installed in the WIM. It is downloaded from the
PowerShell Gallery the first time `Invoke-WinPEStartup` runs after boot.
That's by design — the module always self-updates.

If you need the module baked in (air-gapped builds), copy the module folder
to `OSDRepo\winpe-script\` before building.

## How to rebuild without re-mounting

If you only changed files in the existing `bootmedia` folder (for example,
swapped a `startnet.cmd`), regenerate just the ISO:

```powershell
Update-OSDeployBootISO
```

This skips the DISM mount step and runs `oscdimg.exe` against the existing
folder.

## Next

- [Boot a device into WinPE](03-boot-device.md)
