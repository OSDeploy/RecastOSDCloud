# Surface Catalog Rules

## Field Resolution

Use the current `OSDCloud/core/driverpacks/surface.json` object order for every entry:

1. `CatalogVersion` is the date the entry is added or manually changed in the catalog, formatted as `yy.MM.dd`.
2. `ReleaseDate` is the DriverPack release date from the Microsoft Download Center page Date Published value, formatted as `yy.MM.dd`. If the page does not expose Date Published but the direct MSI is verified, use the MSI response `Last-Modified` date and note that fallback in validation.
3. `Name` is exactly `<Model> [<ReleaseDate>]`.
4. `Manufacturer` is always `Microsoft`.
5. `Model` comes from the System Model column at `https://learn.microsoft.com/en-us/surface/surface-system-sku-reference`, adapted only when the existing catalog uses a shorter family name such as `Surface Laptop 7 Intel`.
6. `SystemId` comes from the System SKU column at the same reference page. Use a string for one SKU and an array when multiple SKUs share the same driver pack.
7. `FileName` is the final path segment of the direct DriverPack MSI URL.
8. `Url` is the direct `https://download.microsoft.com/download/.../*.msi` DriverPack URL.
9. `OperatingSystem` is `Windows 11` for current Surface driver packs unless Microsoft only publishes a Windows 10 pack for that model.
10. `OSArchitecture` is `amd64` for Intel or AMD Surface models and `arm64` for Snapdragon or ARM Surface models.
11. `HashMD5` is `null` unless Microsoft provides a verified MD5 hash.
12. `UpdatePage` is the best matching Microsoft Download Center details page for the model.

## Finding UpdatePage, FileName, and Url

Start at `https://learn.microsoft.com/en-us/surface/manage-surface-driver-and-firmware-updates`. If the table does not expose the direct Download Center details URL clearly, follow the support page for the Surface family and choose the row that best matches the model and processor family.

After adding or updating `UpdatePage`, run `./.github/scripts/Update-MicrosoftCatalog.ps1 -JsonPath 'OSDCloud/core/driverpacks/surface.json'`. The script is the source of truth for picking the direct MSI:

- Scrape `UpdatePage` for `https://download.microsoft.com/download/.../*.msi` links.
- If none are present on the details page, try `https://www.microsoft.com/en-us/download/confirmation.aspx?id=<id>`.
- Prefer MSI links containing `Win11`.
- Among candidates, pick the highest Windows build number in the MSI filename, based on the `_(\d{5})_` pattern.
- Use the page Date Published value for `ReleaseDate` when it is valid; if it is absent, use the verified direct MSI `Last-Modified` date.

## Validation Checklist

- `OSDCloud/core/driverpacks/surface.json` parses with `ConvertFrom-Json`.
- The entry contains all template fields in order.
- `Name` uses the same `ReleaseDate` as the object.
- `Manufacturer` is `Microsoft`.
- `SystemId` values exactly match Microsoft System SKU values.
- `FileName` equals the final path segment of `Url`.
- `Url` matches `https://download.microsoft.com/download/[^\"'<>\s]+\.msi`.
- `OSArchitecture` matches the processor family.
- `UpdatePage` remains populated for future scheduled refreshes.

## Runtime Notes

`Get-OSDCoreDriverPackCatalogSurface` reads `OSDCloud/core/driverpacks/surface.json`, enriches entries with live data from `UpdatePage`, and caches results in `$env:TEMP\osdcloud-driverpack-surface.json`. During deployment, Surface matching depends on `SystemId`, so incorrect System SKU values prevent the correct driver pack from being selected.
