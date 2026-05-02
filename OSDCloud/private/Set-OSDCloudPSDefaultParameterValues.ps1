function Set-OSDCloudPSDefaultParameterValues {
    <#
    .SYNOPSIS
        Applies a two-layer PSDefaultParameterValues system for an OSDeploy module.

    .DESCRIPTION
        Layer 1 - Module defaults: flat key-value pairs in the module-shipped
                  PSDefaultParameterValues.json (core\{Module}\PSDefaultParameterValues.json).
        Layer 2 - User overrides: flat key-value pairs in the user-cache
                  PSDefaultParameterValues.json. Loaded last so any matching key wins.

        Single-line (//) and block (/* */) comments are stripped before parsing to
        support annotated JSON files.

    .PARAMETER ModuleDefaultsPath
        Path to the module-shipped PSDefaultParameterValues.json file.

    .PARAMETER UserDefaultsPath
        Path to the user-cache PSDefaultParameterValues.json file.
        Silent no-op when absent.

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        None.

    .NOTES
        Author:  David Segura
        Company: Recast Software
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ModuleDefaultsPath,

        [Parameter(Mandatory)]
        [string]$UserDefaultsPath
    )

    # Layer 1: module-shipped defaults
    if (Test-Path -LiteralPath $ModuleDefaultsPath -PathType Leaf) {
        try {
            $rawJson = Get-Content -LiteralPath $ModuleDefaultsPath -Raw -ErrorAction Stop
            $rawJson = $rawJson -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
            $moduleDefaults = ConvertFrom-Json $rawJson -ErrorAction Stop
            $moduleDefaults.PSObject.Properties | ForEach-Object {
                $global:PSDefaultParameterValues[$_.Name] = $_.Value
                Write-Verbose "[$(Get-Date -format s)] PSDefaultParameterValues (module): '$($_.Name)' = '$($_.Value)'"
            }
        }
        catch {
            Write-Warning "[$(Get-Date -format s)] Failed to load module PSDefaultParameterValues from '$ModuleDefaultsPath': $_"
        }
    }
    else {
        Write-Verbose "[$(Get-Date -format s)] Module defaults file not found: '$ModuleDefaultsPath'"
    }

    # Layer 2: user profile overrides (silent if absent, wins over layer 1)
    if (Test-Path -LiteralPath $UserDefaultsPath -PathType Leaf) {
        try {
            $rawSettings = Get-Content -LiteralPath $UserDefaultsPath -Raw -ErrorAction Stop
            $rawSettings = $rawSettings -replace '(?m)(?<=^([^"]*|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
            $settings = ConvertFrom-Json $rawSettings -ErrorAction Stop
            $settings.PSObject.Properties | ForEach-Object {
                $global:PSDefaultParameterValues[$_.Name] = $_.Value
                Write-Verbose "[$(Get-Date -format s)] PSDefaultParameterValues (user): '$($_.Name)' = '$($_.Value)'"
            }
        }
        catch {
            Write-Warning "[$(Get-Date -format s)] Failed to load user PSDefaultParameterValues from '$UserDefaultsPath': $_"
        }
    }
}
