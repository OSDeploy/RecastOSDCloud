<#
.SYNOPSIS
Applies offline drivers from a local driver folder to the Windows image.

.DESCRIPTION
Validates the configured driver folder paths and, when present, uses Add-WindowsDriver
to inject all drivers recursively into the offline Windows installation at C:. If no
driver folders are configured or no paths exist, the step exits without error.

.PARAMETER DriverFolderPath
Path(s) to folders that contain driver INF files and subfolders. When omitted, values
are read from $global:OSDCloudWorkflowInvoke.DriverFolderPaths and then
$global:OSDCloudWorkflowInvoke.DriverFolderPath for backward compatibility.

.EXAMPLE
step-Add-WindowsDriver-DriverFolder -DriverFolderPath 'D:\DriverPack'

Injects drivers from D:\DriverPack into the offline Windows image.

.NOTES
Internal workflow step used by OSDCloud deployment tasks.
#>
function step-Add-WindowsDriver-DriverFolder {
    [CmdletBinding()]
    param (
        [System.String[]]
        $DriverFolderPath = @($global:OSDCloudWorkflowInvoke.DriverFolderPaths)
    )
    #=================================================
    $startMessage = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $startMessage; Write-Verbose -Message $startMessage
    #=================================================
    $Error.Clear()
    $logPath = 'C:\Windows\Temp\osdcloud-logs'
    $offlinePath = 'C:\'
    $dismLogPath = Join-Path -Path $logPath -ChildPath 'dism-add-windowsdriver-driverfolder.log'

    if (-not $DriverFolderPath -or $DriverFolderPath.Count -eq 0) {
        if (-not [string]::IsNullOrWhiteSpace([string]$global:OSDCloudWorkflowInvoke.DriverFolderPath)) {
            $DriverFolderPath = @([string]$global:OSDCloudWorkflowInvoke.DriverFolderPath)
        }
    }

    $validDriverFolderPaths = @($DriverFolderPath | Where-Object {
            -not [string]::IsNullOrWhiteSpace([string]$_)
        } | Select-Object -Unique)

    if (-not $validDriverFolderPaths -or $validDriverFolderPaths.Count -eq 0) {
        Write-Verbose "[$(Get-Date -format s)] DriverFolderPath is not set. Skipping driver injection."
        return
    }

    if (-not (Test-Path -LiteralPath $logPath)) {
        New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    }

    foreach ($driverPath in $validDriverFolderPaths) {
        if (-not (Test-Path -LiteralPath $driverPath -PathType Container)) {
            Write-Warning "[$(Get-Date -format s)] DriverFolderPath was not found: $driverPath"
            continue
        }

        Write-Verbose "[$(Get-Date -format s)] Applying drivers from $driverPath"
        try {
            Add-WindowsDriver -Path $offlinePath -Driver $driverPath -Recurse -ForceUnsigned `
                -LogPath $dismLogPath `
                -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning "[$(Get-Date -format s)] Add-WindowsDriver failed for $driverPath. $($_.Exception.Message)"
        }
    }
    #=================================================
    $endMessage = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $endMessage; Write-Debug -Message $endMessage
    #=================================================
}
