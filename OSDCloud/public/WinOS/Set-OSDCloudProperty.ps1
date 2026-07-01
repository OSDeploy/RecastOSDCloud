function Set-OSDCloudProperty {
    <#
    .SYNOPSIS
        Sets an OSDCloud Property override value and persists it to the session file.

    .DESCRIPTION
        Updates the in-session OSDCloud Property override layer ($global:OSDCloudProperty) with a
        single named value, and persists the resulting session values to
        $env:SystemDrive\OSDCloudSession.json so they survive across sessions. This override
        layer is the highest-precedence source read by Get-OSDCloudProperty, which merges the
        sources in the order Module < Registry < Json < session.

        Properties are schema-less: any -Name may be supplied. The -Value is coerced to the type
        given by -Type (String by default) before it is stored.

        This command does not modify the module defaults, the registry, or the Property JSON
        file; it only updates the in-session layer and the OSDCloudSession.json session file.

    .PARAMETER Name
        The property name to set. Any name is allowed.

    .PARAMETER Value
        The value to store. It is coerced to the type given by -Type before being stored.

    .PARAMETER Type
        The value type used to coerce -Value. One of String (default), Boolean, Int32, Int64, or
        Double.

    .EXAMPLE
        Set-OSDCloudProperty -Name OSEdition -Value 'Enterprise'

        Sets the in-session OSEdition value as a String.

    .EXAMPLE
        Set-OSDCloudProperty -Name Force -Value $true -Type Boolean

        Sets the in-session Force value as a Boolean.

    .EXAMPLE
        Set-OSDCloudProperty -Name MaxRetries -Value 5 -Type Int32

        Sets a custom Int32 property in the in-session layer.

    .OUTPUTS
        System.Management.Automation.PSCustomObject

    .NOTES
        Use Get-OSDCloudProperty to read Property override values.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [AllowNull()]
        [System.Object]
        $Value,

        [Parameter(Mandatory = $false)]
        [ValidateSet('String', 'Boolean', 'Int32', 'Int64', 'Double')]
        [System.String]
        $Type = 'String'
    )

    $Error.Clear()
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"

    # Coerce the supplied value to the requested type
    $typedValue = ConvertTo-OSDCloudPropertyValue -Name $Name -Value $Value -Type $Type
    if ($null -eq $typedValue) {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Value '$Value' could not be coerced to type '$Type' for property '$Name'."
        return
    }

    # Update the in-session Property override layer
    if (-not $global:OSDCloudProperty) {
        $global:OSDCloudProperty = [ordered]@{}
    }
    $global:OSDCloudProperty[$Name] = $typedValue
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Set $Name = $typedValue ($Type)"

    # Persist the in-session values to the session file for cross-session persistence
    $sessionPath = Join-Path -Path "$env:SystemDrive\" -ChildPath 'OSDCloudSession.json'
    try {
        [pscustomobject]$global:OSDCloudProperty | ConvertTo-Json -Depth 4 | Set-Content -Path $sessionPath -Encoding UTF8 -Force -ErrorAction Stop
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Session written: $sessionPath"
    }
    catch {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to write session file '$sessionPath': $($_.Exception.Message)"
    }

    return [pscustomobject]$global:OSDCloudProperty
}
