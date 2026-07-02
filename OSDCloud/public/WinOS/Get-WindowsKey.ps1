function Get-WindowsKey {
    <#
    .SYNOPSIS
        Returns the embedded Windows product key from UEFI firmware.

    .DESCRIPTION
        Queries the SoftwareLicensingService WMI class and returns the
        OA3xOriginalProductKey value when present. This implementation uses
        System.Management APIs compatible with .NET Framework 4.6 and works
        in WinPE when firmware exposes an embedded product key.

    .OUTPUTS
        System.String. The embedded Windows product key.

    .EXAMPLE
        Get-WindowsKey

        Returns the embedded OEM Windows product key from UEFI firmware.

    .NOTES
        Returns no output when a firmware key is not present.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    $Error.Clear()
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"

    try {
        $query = 'SELECT OA3xOriginalProductKey FROM SoftwareLicensingService'
        $searcher = New-Object System.Management.ManagementObjectSearcher $query
        $results = $searcher.Get()

        foreach ($result in $results) {
            $productKey = [string]$result.OA3xOriginalProductKey
            if (-not [string]::IsNullOrWhiteSpace($productKey)) {
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Found firmware Windows key"
                Write-Output $productKey.Trim()
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
                return
            }
        }

        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] No firmware Windows key found"
    }
    catch {
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $_.Exception,
            'GetWindowsKeyFailed',
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )
        $PSCmdlet.WriteError($errorRecord)
    }

    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
}
