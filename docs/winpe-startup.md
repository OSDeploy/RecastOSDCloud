# WinPE Startup Guide

`Invoke-WinPEStartup` is the single entry point for the OSDCloud WinPE boot
sequence. Call it from your WinPE `startnet.cmd` or from an OSDWorkspace
startup script.

## Guard condition

The function runs **only when `$env:SystemDrive -eq 'X:'`** (the WinPE RAM
drive). If called in a full Windows session it writes a warning and exits
immediately without running any steps.

## Startup sequence

The sequence always runs in the following order. Steps 1–3 run
unconditionally before the startup profile is selected or loaded. Steps 4
onwards can be skipped individually; see
[Parameter reference](#parameter-reference) below.

```
 1. Environment init    Initialize-WinPEStartupEnvironment
 2. Drivers             Initialize-WinPEStartupDrivers
 3. Files               Initialize-WinPEStartupFiles
 4. wpeinit / wpeutil   Initialize-WinPEStartupMain
 5. On-screen keyboard  Invoke-WinPEStartupManager OSK
 6. PnP devices         Invoke-WinPEStartupManager DeviceHardware
 7. PnP errors          Invoke-WinPEStartupManager DeviceErrors
 8. Wi-Fi               Invoke-WinPEStartupManager WiFi
 9. IP config           Invoke-WinPEStartupManager IPConfig
10. Module update       Invoke-WinPEStartupManager UpdateModule
11. InvokeStartupCommand  (child powershell.exe)
12. InvokeMainCommand     (child powershell.exe)
13. InvokeShutdownCommand (child powershell.exe)
```

## Skip flags

| Parameter | Step skipped |
|---|---|
| `-SkipOnScreenKeyboard` | Step 5 |
| `-SkipWiFi` | Step 8 |
| `-SkipIPConfig` | Step 9 |
| `-SkipUpdateOSDCloud` | Step 10 (OSDCloud module update only) |

## Opt-in flags

| Parameter | Step enabled |
|---|---|
| `-ShowPnpDevices` | Step 6 — opens the PnP device hardware window |
| `-ShowPnpErrors` | Step 7 — opens the PnP device error window |

## Default module behaviour

The module ships with a default `InvokeMainCommand` that shows device info
and launches the deployment UI:

```powershell
Show-OSDCloudDeviceInfo
Deploy-OSDCloud
```

`InvokeMainCommandNoExit` defaults to `true`, so the child window stays open after the commands complete — no `pause` is needed.

`InvokeShutdownCommand` defaults to an empty array, so no shutdown command runs automatically.

Override these defaults using a startup profile. See
[psoptions.md](psoptions.md) for details.

## InvokeXxxCommand behaviour

Commands passed to `-InvokeStartupCommand`, `-InvokeMainCommand`, and
`-InvokeShutdownCommand` are executed in a child `powershell.exe` process.
All entries in the array are joined and passed via `-EncodedCommand` (base64)
to avoid quoting issues.

**HTTPS URLs are auto-wrapped:**

```powershell
# This entry:
'https://raw.githubusercontent.com/example/repo/main/deploy.ps1'

# Becomes:
Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/example/repo/main/deploy.ps1' | Invoke-Expression
```

> **Security note:** Only pass URLs you trust. Content fetched via
> `Invoke-RestMethod | Invoke-Expression` runs with full privileges in WinPE.

## USB startup profiles

JSON files placed at `<Drive>:\WinPEStartup\Profiles\*.json` on any connected
drive are loaded as parameter defaults before the function body executes.

- If **multiple profiles** are found a numbered menu is presented and the
  operator selects one.
- If **exactly one profile** is found it is applied automatically.
- Profiles have higher precedence than the module-shipped `core/PSDefaultParameterValues.json`.

**Example profile file (`mysite.json`):**

```json
{
    "SkipWiFi": true,
    "SkipIPConfig": true,
    "InvokeMainCommand": [
        "Show-OSDCloudDeviceInfo",
        "Deploy-OSDCloud -WorkflowName latest",
        "pause"
    ]
}
```

## Examples

### Minimal call from startnet.cmd

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "Install-Module OSDCloud -SkipPublisherCheck -Force; Import-Module OSDCloud; Invoke-WinPEStartup"
```

### Skip Wi-Fi on a wired-only deployment

```powershell
Invoke-WinPEStartup -SkipWiFi -SkipIPConfig
```

### Custom main command pointing to a remote script

```powershell
Invoke-WinPEStartup -InvokeMainCommand 'https://raw.githubusercontent.com/myorg/myrepo/main/WinPEDeploy.ps1'
```

### Install additional modules during startup

```powershell
Invoke-WinPEStartup -InstallModule 'OSD','OSDWorkspace'
```

## Parameter reference

For the full parameter reference including types, defaults, and YAML blocks
see [../OSDCloud/docs/Invoke-WinPEStartup.md](../OSDCloud/docs/Invoke-WinPEStartup.md).

For customising defaults without modifying the function call see
[psoptions.md](psoptions.md).
