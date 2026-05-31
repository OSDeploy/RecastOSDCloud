# Customize the Deployment

## When to use this

You ran the default deployment from [guide 4](04-deploy-windows.md) and now
need to change something — a different OS build, a different edition, a
skipped step, or a different workflow channel.

## Why workflow channels exist

A **workflow channel** is a folder under `OSDCloud/workflow/` that bundles:

- A task definition (which steps run, in what order, which are skipped).
- Per-architecture OS / edition / language options shown in the UX.
- UI configuration.

Channels let the same module deploy with different policies — production
versus pilot versus development — without rewriting code.

## Available channels

| Channel | When to use it |
|---|---|
| `default` | Production. Windows 11 25H2 / 24H2 / 23H2. The standard 40-step task. |
| `latest` | Same as `default` but tracks the newest OS catalog. |
| `classic` | Legacy OSDCloud (OSD v1) compatibility flow. |
| `insiders` | Insider Preview ESDs for testing. |
| `dev-alpha`, `dev-beta`, `dev-device` | Module development channels — do not use in production. |
| `legacy` | Historic baseline kept for reference. |

Select one with `-WorkflowName`:

```powershell
Deploy-OSDCloud -WorkflowName latest
```

## Change OS, edition, or language

These choices live in `workflow/<channel>/os-amd64.json` and
`workflow/<channel>/os-arm64.json`. The UX reads them at runtime.

### Operator-driven (one-off)

Just pick a different option in the UX before clicking Start.

### Policy change (everyone gets it)

Edit the JSON for the channel. For example, default the `default` channel
to Enterprise + en-gb:

```jsonc
{
  "OperatingSystem": { "default": "Windows 11 25H2", "values": ["Windows 11 25H2"] },
  "OSActivation":    { "default": "Volume",          "values": ["Volume"] },
  "OSEdition":       { "default": "Enterprise",      "values": [{ "Edition": "Enterprise", "EditionId": "Enterprise" }] },
  "OSLanguageCode":  { "default": "en-gb",           "values": ["en-gb"] }
}
```

Restrict `values` to one entry to force a choice without showing alternatives.

ARM64 has fewer editions (no N or Education variants) — see [guide 7](07-arm64-devices.md).

## Skip or enable individual steps

Each step entry in `workflow/<channel>/tasks/osdcloud.json` has a `skip`
field. Toggle it without removing the step:

```jsonc
{
    "name": "Apply Microsoft Update Drivers - Disk",
    "command": "step-Add-WindowsDriver-Disk",
    "skip": false      // was true — now this step runs
}
```

`testinfullos: true` means a step also runs when `Deploy-OSDCloud -CLI` is
launched from a full Windows session (for testing). Steps without that flag
are silently skipped outside WinPE.

## The default workflow (40 steps)

Phases and per-step notes for the `default` channel's `osdcloud.json` task.
Steps marked **Skipped** have `"skip": true` shipped from the catalog.

### Phase 1 — Validate

| # | Step | Notes |
|---|---|---|
| 1 | Initialize OSDCloud Workflow | Also runs in full OS |
| 2 | Initialize OSDCloud Logs | |
| 3 | Test TargetDisk | Confirms a usable local disk |
| 4 | Test WindowsImage | Confirms the chosen image is reachable |
| 5 | Test DriverPack | Confirms the OEM driver pack is reachable |

### Phase 2 — Pre-install

| # | Step | Notes |
|---|---|---|
| 6 | Remove USB Drive Letters | Keeps USB out of the way of partitioning |
| 7 | Clear Local Disk | **Destructive** — wipes the target disk |
| 8 | Partition Local Disk | UEFI / GPT layout |
| 9 | Restore USB Drive Letters | |
| 10 | Enable High Performance Power Plan | Prevents sleep mid-deploy |

### Phase 3 — Install

| # | Step | Notes |
|---|---|---|
| 11 | Download Windows ESD from Microsoft | |
| 12 | Select Windows Image Index | Matches the chosen edition |
| 13 | Expand Windows Image to Local Disk | `Expand-WindowsImage` |
| 14 | Restart Logs | Switches log path to `C:\Windows\Temp\osdcloud-logs` |
| 15 | Verify Windows Edition on Local Disk | |
| 16 | Remove the downloaded Windows Image | Frees space |
| 17 | Apply BCDBoot Configuration | |

### Phase 4 — Drivers

| # | Step | Notes |
|---|---|---|
| 18 | Export WinPE OEM Drivers to Local Disk | |
| 19 | Apply WinPE Drivers to offline Windows Image | |
| 20 | Apply WinPE Drivers to offline WinRE | |
| 21 | Firmware: Download from Microsoft Update Catalog | |
| 22 | Firmware: Apply Driver | |
| 23 | OEM DriverPack: Download from OEM | Dell / HP / Lenovo / Microsoft / Panasonic |
| 24 | OEM DriverPack: Apply or stage in SetupComplete.cmd | |
| 25 | Apply Drivers from a OSD folder match | Pulls from local `OSD\` folders if present |
| 26 | Download Drivers from Microsoft Update Catalog | |
| 27 | Apply MU Drivers — All | |
| 28 | Apply MU Drivers — Disk | **Skipped** |
| 29 | Apply MU Drivers — Net | |
| 30 | Apply MU Drivers — Scsi | **Skipped** |

### Phase 5 — Finalize

| # | Step | Notes |
|---|---|---|
| 31 | Hotfix for Setup Displayed Eula | Registry value |
| 32 | Update PowerShell Modules — Offline | Into the offline Windows image |
| 33 | Save PowerShell Module OSD | **Skipped** |
| 34 | Save PowerShell Module WindowsAutopilotIntune | **Skipped** |
| 35 | Save PowerShell Module Microsoft.Graph.Groups | **Skipped** |
| 36 | Save PowerShell Module Microsoft.Graph.Authentication | **Skipped** |
| 37 | Save PowerShell Module Microsoft.Graph.Identity.DirectoryManagement | **Skipped** |
| 38 | Export OS Information to Logs | |
| 39 | Stop Logs | |
| 40 | Stop Workflow | |

Enable the Save PowerShell Module steps when you want those modules
pre-cached on the deployed device — useful for Autopilot-adjacent scripts.

## Add a brand-new step

1. Write the step function under `OSDCloud/private/steps/<phase>/step-<verb>-<noun>.ps1`.
2. Add a JSON entry in `workflow/<channel>/tasks/osdcloud.json` referencing the function name as `command`.
3. Follow the schema in `.github/instructions/workflow-tasks.instructions.md`.

## Next

- [Unattended deployment with a USB profile](06-unattended-usb-profile.md) — skip the operator entirely.
- [Troubleshoot](09-troubleshooting.md) if your customizations break the workflow.
