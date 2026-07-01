function Get-OSDCloudProperty {
    <#
    .SYNOPSIS
        Gets OSDCloud Property override values.

    .DESCRIPTION
        Returns the OSDCloud Property override values that control deployment configuration.
        By default, the effective values assembled from every method are returned: the module
        defaults, the JSON file, the in-session $global:OSDCloudProperty layer, and the session
        file ($env:SystemDrive\OSDCloudSession.json) are merged in increasing order of precedence
        (Module < Json < In-session < Session), so the result reflects all properties set by any
        source even when a deploy has not run yet.
        Use -Source to inspect an individual layer (the module defaults or the JSON file) which
        is useful for troubleshooting override precedence.

        With no -Name, all available Property values for the selected source are returned as a
        single object. With -Name, only the value for that property is returned.

        When -Source is Json, every value stored in the file is returned, including names that
        are not part of the Property whitelist. Whitelisting only governs which values
        participate in the override layer, not what this cmdlet displays.

    .PARAMETER Name
        The name of a single Property to return. When omitted, all properties for the source
        are returned.

    .PARAMETER Source
        The layer to read from:
            Property (default) - the effective values merged from every method
                                 (Module < Json < in-session < session file)
            Module             - the module-default values shipped in core\OSDCloudProperty.json
            Json               - values stored in the Property JSON file

    .PARAMETER Path
        Optional path used when -Source is Json. Defaults to the environment-appropriate
        Property JSON path.

    .EXAMPLE
        Get-OSDCloudProperty

        Returns all effective Property override values merged from every method for the
        current session.

    .EXAMPLE
        Get-OSDCloudProperty -Name OSEdition

        Returns the effective OSEdition override value.

    .EXAMPLE
        Get-OSDCloudProperty -Source Json

        Returns the Property values stored in the JSON file.

    .OUTPUTS
        System.Management.Automation.PSCustomObject

    .NOTES
        Use Set-OSDCloudProperty to set or persist Property override values.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Property', 'Module', 'Json')]
        [System.String]
        $Source = 'Property',

        [Parameter(Mandatory = $false)]
        [System.String]
        $Path
    )

    $Error.Clear()
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Source: $Source"

    switch ($Source) {
        'Module' {
            # Surface ALL values stored in the module-default JSON file for inspection, not just
            # the whitelisted Property keys.
            $values = [ordered]@{}
            $moduleBase = $MyInvocation.MyCommand.Module.ModuleBase
            $modulePath = if ($PSBoundParameters.ContainsKey('Path')) {
                $Path
            }
            elseif ($moduleBase) {
                Join-Path -Path $moduleBase -ChildPath 'core\OSDCloudProperty.json'
            }
            else {
                $null
            }
            if ($modulePath -and (Test-Path -Path $modulePath)) {
                try {
                    $rawJsonContent = Get-Content -Path $modulePath -Raw
                    $jsonContent = $rawJsonContent -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
                    $jsonObject = ConvertFrom-Json -InputObject $jsonContent
                    foreach ($property in $jsonObject.PSObject.Properties) {
                        $typedValue = ConvertTo-OSDCloudPropertyValue -Name $property.Name -Value $property.Value
                        if ($null -eq $typedValue) {
                            $typedValue = $property.Value
                        }
                        $values[$property.Name] = $typedValue
                    }
                }
                catch {
                    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to read JSON: $modulePath"
                }
            }
            else {
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Module default JSON file not found: $modulePath"
            }
        }
        'Json' {
            # Surface ALL values stored in the JSON file for inspection, not just the whitelisted
            # Property keys.
            $values = [ordered]@{}
            $jsonPath = if ($PSBoundParameters.ContainsKey('Path')) { $Path } else { Get-OSDCloudPropertyPath }
            if ($jsonPath -and (Test-Path -Path $jsonPath)) {
                try {
                    $rawJsonContent = Get-Content -Path $jsonPath -Raw
                    $jsonContent = $rawJsonContent -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
                    $jsonObject = ConvertFrom-Json -InputObject $jsonContent
                    foreach ($property in $jsonObject.PSObject.Properties) {
                        $typedValue = ConvertTo-OSDCloudPropertyValue -Name $property.Name -Value $property.Value
                        if ($null -eq $typedValue) {
                            $typedValue = $property.Value
                        }
                        $values[$property.Name] = $typedValue
                    }
                }
                catch {
                    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to read JSON: $jsonPath"
                }
            }
            else {
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] JSON file not found: $jsonPath"
            }
        }
        default {
            # Assemble the effective view from every method, layered in increasing order of
            # precedence so the result reflects all properties set by any source, even when a
            # deploy has not run yet:
            #   1. Module defaults (lowest) - core\OSDCloudProperty.json shipped with the module
            #   2. JSON file                - Property JSON file
            #   3. In-session               - $global:OSDCloudProperty (parameters)
            #   4. Session file (highest)   - $env:SystemDrive\OSDCloudSession.json (Set-OSDCloudProperty)
            $values = [ordered]@{}

            # Layer 1: Module defaults
            $moduleBase = $MyInvocation.MyCommand.Module.ModuleBase
            $moduleDefaultPath = if ($moduleBase) {
                Join-Path -Path $moduleBase -ChildPath 'core\OSDCloudProperty.json'
            }
            else {
                $null
            }
            if ($moduleDefaultPath) {
                $moduleValues = Get-OSDCloudPropertyFromJson -Path $moduleDefaultPath
                foreach ($key in $moduleValues.Keys) {
                    $values[$key] = $moduleValues[$key]
                }
            }

            # Layer 2: JSON file
            $jsonValues = if ($PSBoundParameters.ContainsKey('Path')) {
                Get-OSDCloudPropertyFromJson -Path $Path
            }
            else {
                Get-OSDCloudPropertyFromJson
            }
            foreach ($key in $jsonValues.Keys) {
                $values[$key] = $jsonValues[$key]
            }

            # Layer 3: In-session overrides
            if ($global:OSDCloudProperty) {
                foreach ($key in $global:OSDCloudProperty.Keys) {
                    $values[$key] = $global:OSDCloudProperty[$key]
                }
            }

            # Layer 4: Session persistence file (highest precedence) - values written by
            # Set-OSDCloudProperty to $env:SystemDrive\OSDCloudSession.json
            $sessionPath = Join-Path -Path "$env:SystemDrive\" -ChildPath 'OSDCloudSession.json'
            if (Test-Path -Path $sessionPath -PathType Leaf) {
                $sessionValues = Get-OSDCloudPropertyFromJson -Path $sessionPath
                foreach ($key in $sessionValues.Keys) {
                    $values[$key] = $sessionValues[$key]
                }
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('Name')) {
        if ($values.Contains($Name)) {
            return $values[$Name]
        }
        return $null
    }

    return [pscustomobject]$values
}
