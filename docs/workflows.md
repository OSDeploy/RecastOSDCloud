# Deployment Workflows

A *workflow channel* defines which OS options are available and which
deployment steps run when you call `Deploy-OSDCloud`. Channels live in the
`workflow/` directory of the module.

## Selecting a channel

Pass the channel name to `Deploy-OSDCloud` with `-WorkflowName`:

```powershell
# Default (recommended for most deployments)
Deploy-OSDCloud

# Specific channel
Deploy-OSDCloud -WorkflowName latest
Deploy-OSDCloud -WorkflowName classic
```

The default channel name is `default`. Available channel names are determined
by subdirectories under `<ModuleBase>\workflow\`.

## Available channels

| Channel | Description |
|---|---|
| `default` | Recommended for most deployments. Includes Windows 11 25H2, 24H2, and 23H2 OS options. Runs the full 39-step OSDCloud task. |
| `latest` | Targets the most recent Windows 11 release only. Minimal workflow configuration — inherits step list from the default task. |
| `classic` | Legacy-compatible deployment path with a simplified UX. |
| `insiders` | Windows Insider Program builds. Not for production use. |
| `legacy` | Retained for compatibility with older deployment scripts. Minimal active maintenance. |
| `dev-alpha` | Active development channel. Experimental features, expect breaking changes. |
| `dev-beta` | Pre-release testing channel. More stable than alpha; not production-ready. |
| `dev-device` | Development workflow with a WPF application UI for testing device-specific logic. |

## Channel directory layout

```
workflow/
  <channel>/
    tasks/                    # JSON task definitions
      <task>.json
    ux/                       # UI configuration
      <ux-settings>.json
    os-amd64.json             # OS and language options for x64
    os-arm64.json             # OS and language options for ARM64
```

Not all channels have all directories. Only `default` and `dev-device` have
both `tasks/` and `ux/` directories.

## OS configuration files

`os-amd64.json` and `os-arm64.json` define the choices presented in the
deployment UI for each processor architecture. The `default` channel
(amd64) offers:

| Setting | Default | Available values |
|---|---|---|
| Operating System | Windows 11 25H2 | Windows 11 25H2, 24H2, 23H2 |
| Activation | Retail | Retail, Volume |
| Edition | Pro | Home, Home N, Pro, Pro N, Education, Education N, Enterprise, Enterprise N |
| Language | en-us | 38 language codes (ar-sa through zh-tw) |

## Default workflow task (39 steps)

The `default` channel runs the `OSDCloud` task, which executes the following
steps in order. Steps marked **Skipped** have `skip: true` in the task JSON
and are not executed by default.

### Phase 1 — Validation

| # | Name | Notes |
|---|---|---|
| 1 | Initialize OSDCloud Workflow | Runs in full OS too (`testInFullOS: true`) |
| 2 | Initialize OSDCloud Logs | |
| 3 | Test TargetDisk | Validates that a compatible local disk exists |
| 4 | Test WindowsImage | Checks the target Windows image |
| 5 | Test DriverPack | Checks the selected driver pack |

### Phase 2 — Pre-install

| # | Name | Notes |
|---|---|---|
| 6 | Remove USB Drive Letters | Prevents USB partitions from receiving drive letters during partitioning |
| 7 | Clear Local Disk | **Destructive** — wipes the target disk |
| 8 | Partition Local Disk | Creates EFI system + Windows partitions |
| 9 | Restore USB Drive Letters | Re-assigns USB drive letters |
| 10 | Enable High Performance Power Plan | Prevents the device from sleeping during deployment |

### Phase 3 — Install

| # | Name | Notes |
|---|---|---|
| 11 | Download Windows ESD from Microsoft | Downloads the ESD from Microsoft servers |
| 12 | Select Windows Image Index | Picks the correct edition index from the ESD |
| 13 | Expand Windows Image to Local Disk | Applies the image with `Expand-WindowsImage` |
| 14 | Restart Logs | |
| 15 | Verify Windows Edition | Confirms the correct edition was applied |
| 16 | Remove Downloaded Windows Image | Cleans up the local ESD copy |
| 17 | Apply BCDBoot | Writes the boot configuration |

### Phase 4 — Drivers

| # | Name | Notes |
|---|---|---|
| 18 | Export WinPE OEM Drivers to Local Disk | Copies WinPE OEM drivers for later use |
| 19 | Apply WinPE Drivers to Windows Image | Injects WinPE OEM drivers into the Windows installation |
| 20 | Apply WinPE Drivers to WinRE | Injects WinPE OEM drivers into WinRE |
| 21 | Firmware: Download from MUC | Downloads firmware updates from Microsoft Update Catalog |
| 22 | Firmware: Apply Driver | Injects firmware drivers |
| 23 | OEM DriverPack: Download | Downloads the OEM driver pack (Dell, HP, Lenovo, Panasonic) |
| 24 | OEM DriverPack: Apply/Stage | Injects or stages the OEM driver pack |
| 25 | Download Drivers from MUC | Downloads additional drivers from Microsoft Update Catalog |
| 26 | Apply MU Drivers – All | Injects all Microsoft Update drivers |
| 27 | Apply MU Drivers – Disk | **Skipped by default** |
| 28 | Apply MU Drivers – Net | Injects Microsoft Update network drivers |
| 29 | Apply MU Drivers – Scsi | **Skipped by default** |

### Phase 5 — Post-install / Finalize

| # | Name | Notes |
|---|---|---|
| 30 | Hotfix Setup DisplayedEula | Sets the `SetupDisplayedEula` registry value |
| 31 | Update PowerShell Modules Offline | Updates modules in the offline Windows image |
| 32 | Save PS Module: OSD | **Skipped by default** |
| 33 | Save PS Module: WindowsAutopilotIntune | **Skipped by default** |
| 34 | Save PS Module: Microsoft.Graph.Groups | **Skipped by default** |
| 35 | Save PS Module: Microsoft.Graph.Authentication | **Skipped by default** |
| 36 | Save PS Module: Microsoft.Graph.Identity.DirectoryManagement | **Skipped by default** |
| 37 | Export OS Info to Logs | Writes OS metadata to the log directory |
| 38 | Stop Logs | |
| 39 | Stop Workflow | |

## Skip flags in task JSON

Each step in a task JSON file has a `skip` field (boolean). Set `"skip": true`
to disable a step without removing it:

```json
{
    "name": "Apply MU Drivers - Disk",
    "command": "step-Add-WindowsDriver-Disk",
    "skip": true
}
```

The `testInFullOS` flag (`true`/`false`) controls whether a step runs when
`Deploy-OSDCloud -CLI` is called from a full Windows session (e.g. for testing
without WinPE). Steps without `"testInFullOS": true` are skipped in that
scenario.

## Adding a deployment step

1. Implement the step function in `private/steps/` following the naming
   convention `step-<Verb>-<Noun>.ps1`.
2. Add a JSON entry to the appropriate `workflow/<channel>/tasks/<task>.json`
   referencing your function name as the `command` value.
3. See [CONTRIBUTING.md](../CONTRIBUTING.md) and the
   workflow-tasks instructions for the required JSON schema.
