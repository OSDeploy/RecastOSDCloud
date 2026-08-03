---
name: add-surface-model
description: "Use when adding or validating a Microsoft Surface model in OSDCloud surface.json, resolving System SKU/SystemId, Surface driver pack UpdatePage, direct MSI Url, FileName, ReleaseDate, OSArchitecture, and catalog properties."
argument-hint: "Surface model name, for example: Surface Laptop 8 Intel"
---

# Add Surface Model

Use this skill to add or validate Microsoft Surface driver pack entries in `OSDCloud/core/driverpacks/surface.json`.

## Workflow

1. Review the current catalog entry shape in `OSDCloud/core/driverpacks/surface.json` and use [the template](./assets/surface-model-template.json) for field order.
2. Follow [the Surface catalog rules](./references/surface-catalog-rules.md) to resolve each property from Microsoft sources and local catalog conventions.
3. Add or update one JSON object in `surface.json`, keeping entries sorted by `Model`.
4. Run `.\.github\scripts\Update-MicrosoftCatalog.ps1 -JsonPath 'OSDCloud\core\driverpacks\surface.json'` to refresh `FileName`, `Url`, and `ReleaseDate` from `UpdatePage`.
5. Validate JSON parsing, direct MSI URL shape, `FileName`/`Url` consistency, and runtime loading through `Get-OSDCloudCatalogSurface` when practical.

## Required Sources

- System model and System SKU reference: `https://learn.microsoft.com/en-us/surface/surface-system-sku-reference`
- Surface driver and firmware update pages: `https://learn.microsoft.com/en-us/surface/manage-surface-driver-and-firmware-updates`
- Support model pages linked from Microsoft Surface driver pages when they expose clearer Download Center IDs.
- Repo updater behavior in `.github/scripts/Update-MicrosoftCatalog.ps1`.

## Stop Conditions

Do not leave placeholder values in `surface.json`. If the Microsoft Download Center page cannot yield a direct `.msi` URL through the updater or manual verification, pause and report the blocked fields instead of committing guessed values.
