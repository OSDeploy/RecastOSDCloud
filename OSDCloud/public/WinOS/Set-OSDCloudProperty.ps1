function Set-OSDCloudProperty {
    <#
    .SYNOPSIS
        Sets, removes, or clears OSDCloud Property override values persisted to the session file.

    .DESCRIPTION
        Manages the OSDCloud Property session persistence layer stored in
        $env:SystemDrive\OSDCloudSession.json. This file is an independent, highest-precedence
        layer read by Get-OSDCloudProperty, which merges the sources in the order
        Module < Json < in-session < session.

        The command always reads the existing session file, applies the requested change, and
        writes the merged result back, so previously persisted keys are never lost:

            Set    (default) - -Name/-Value[/-Type] adds or updates a single persisted key.
            Remove           - -Name -Remove deletes a single persisted key.
            Clear            - -Clear deletes the entire session file.

        Properties are schema-less: any -Name may be supplied. In Set mode the -Value is coerced
        to the type given by -Type (String by default) before it is stored.

        This command does not modify the module defaults or the Property JSON file; it only
        updates the in-session $global:OSDCloudProperty layer and the OSDCloudSession.json
        session file.

    .PARAMETER Name
        The property name to set or remove. Any name is allowed.

    .PARAMETER Value
        The value to store. It is coerced to the type given by -Type before being stored.

    .PARAMETER Type
        The value type used to coerce -Value. One of String (default), Boolean, Int32, Int64, or
        Double.

    .PARAMETER Remove
        Removes the property named by -Name from the in-session layer and the session file.

    .PARAMETER Clear
        Clears the entire session by deleting the OSDCloudSession.json session file.

    .EXAMPLE
        Set-OSDCloudProperty -Name OSEdition -Value 'Enterprise'

        Sets the persisted OSEdition value as a String.

    .EXAMPLE
        Set-OSDCloudProperty -Name Force -Value $true -Type Boolean

        Sets the persisted Force value as a Boolean.

    .EXAMPLE
        Set-OSDCloudProperty -Name MaxRetries -Value 5 -Type Int32

        Sets a custom Int32 property in the session file.

    .EXAMPLE
        Set-OSDCloudProperty -Name OSEdition -Remove

        Removes the persisted OSEdition value from the session file.

    .EXAMPLE
        Set-OSDCloudProperty -Clear

        Deletes the OSDCloudSession.json session file, clearing all persisted values.

    .OUTPUTS
        System.Management.Automation.PSCustomObject

    .NOTES
        Use Get-OSDCloudProperty to read Property override values.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Set')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Set')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Remove')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Set')]
        [AllowNull()]
        [System.Object]
        $Value,

        [Parameter(Mandatory = $false, ParameterSetName = 'Set')]
        [ValidateSet('String', 'Boolean', 'Int32', 'Int64', 'Double')]
        [System.String]
        $Type = 'String',

        [Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
        [System.Management.Automation.SwitchParameter]
        $Remove,

        [Parameter(Mandatory = $true, ParameterSetName = 'Clear')]
        [System.Management.Automation.SwitchParameter]
        $Clear
    )

    $Error.Clear()
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"

    $sessionPath = Join-Path -Path "$env:SystemDrive\" -ChildPath 'OSDCloudSession.json'

    # Clear: delete the entire session file and return.
    if ($PSCmdlet.ParameterSetName -eq 'Clear') {
        if (Test-Path -Path $sessionPath -PathType Leaf) {
            try {
                Remove-Item -Path $sessionPath -Force -ErrorAction Stop
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Session cleared: $sessionPath"
            }
            catch {
                Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to delete session file '$sessionPath': $($_.Exception.Message)"
            }
        }
        else {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Session file not found: $sessionPath"
        }

        # Drop the persisted keys from the in-session layer as well.
        if ($global:OSDCloudProperty) {
            $global:OSDCloudProperty = [ordered]@{}
        }

        return
    }

    # Read the existing session file so persisted keys are preserved (read-merge-write).
    $sessionValues = Get-OSDCloudPropertyFromJson -Path $sessionPath

    if ($PSCmdlet.ParameterSetName -eq 'Remove') {
        if ($sessionValues.Contains($Name)) {
            $sessionValues.Remove($Name)
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Removed $Name from session"
        }
        else {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] $Name not present in session"
        }

        # Keep the in-session layer in sync.
        if ($global:OSDCloudProperty -and $global:OSDCloudProperty.Contains($Name)) {
            $global:OSDCloudProperty.Remove($Name)
        }
    }
    else {
        # Set: coerce the supplied value to the requested type.
        $typedValue = ConvertTo-OSDCloudPropertyValue -Name $Name -Value $Value -Type $Type
        if ($null -eq $typedValue) {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Value '$Value' could not be coerced to type '$Type' for property '$Name'."
            return
        }

        $sessionValues[$Name] = $typedValue

        # Update the in-session Property override layer.
        if (-not $global:OSDCloudProperty) {
            $global:OSDCloudProperty = [ordered]@{}
        }
        $global:OSDCloudProperty[$Name] = $typedValue
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Set $Name = $typedValue ($Type)"
    }

    # Persist the merged session values back to the session file.
    try {
        [pscustomobject]$sessionValues | ConvertTo-Json -Depth 4 | Set-Content -Path $sessionPath -Encoding UTF8 -Force -ErrorAction Stop
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Session written: $sessionPath"
    }
    catch {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to write session file '$sessionPath': $($_.Exception.Message)"
    }

    return [pscustomobject]$sessionValues
}
