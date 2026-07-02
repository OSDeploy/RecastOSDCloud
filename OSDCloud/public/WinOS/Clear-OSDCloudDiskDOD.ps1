function Clear-OSDCloudDiskDOD {
	<#
	.SYNOPSIS
	Performs a DoD-style sanitizing wipe on the selected deployment disk.

	.DESCRIPTION
	Uses DiskPart clean all to overwrite the entire selected disk surface.
	The function is designed for WinPE usage and only executes the wipe when
	-Force is explicitly provided.

	.PARAMETER DiskNumber
	Optional disk number to sanitize. If omitted, the function uses the current
	selected deployment disk from $global:OSDCloudDeploy.DeploymentDiskObject,
	and falls back to the first result from Get-DeploymentDiskObject.

	.PARAMETER Force
	Required to perform the destructive clean all operation.

	.EXAMPLE
	Clear-OSDCloudDiskDOD

	Displays the selected target disk and help text, then exits without wiping.

	.EXAMPLE
	Clear-OSDCloudDiskDOD -Force

	Performs DiskPart clean all on the selected deployment disk in WinPE.

	.EXAMPLE
	Clear-OSDCloudDiskDOD -DiskNumber 1 -Force

	Performs DiskPart clean all on disk 1 in WinPE.

	.NOTES
	Intended for Windows PowerShell 5.1 in WinPE (.NET Framework 4.6 compatible).
	#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param (
		[Alias('Disk','Number')]
		[uint32]$DiskNumber,

		[switch]$Force
	)

	$Error.Clear()
	Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"

	if ($env:SystemDrive -ne 'X:') {
		$errorRecord = [System.Management.Automation.ErrorRecord]::new(
			[System.InvalidOperationException]::new('Clear-OSDCloudDiskDOD must be run in WinPE (SystemDrive X:).'),
			'NotInWinPE',
			[System.Management.Automation.ErrorCategory]::InvalidOperation,
			$env:SystemDrive
		)
		$PSCmdlet.ThrowTerminatingError($errorRecord)
	}

	$targetDisk = $null

	if ($PSBoundParameters.ContainsKey('DiskNumber')) {
		try {
			$targetDisk = @(Get-DeploymentDiskObject -Number $DiskNumber -ErrorAction Stop | Select-Object -First 1)
		}
		catch {
			$errorRecord = [System.Management.Automation.ErrorRecord]::new(
				$_.Exception,
				'DiskNotFound',
				[System.Management.Automation.ErrorCategory]::ObjectNotFound,
				$DiskNumber
			)
			$PSCmdlet.ThrowTerminatingError($errorRecord)
		}
	}
	elseif ($global:OSDCloudDeploy -and $global:OSDCloudDeploy.DeploymentDiskObject) {
		$targetDisk = @($global:OSDCloudDeploy.DeploymentDiskObject | Select-Object -First 1)
	}
	else {
		try {
			$targetDisk = @(Get-DeploymentDiskObject -ErrorAction Stop | Select-Object -First 1)
		}
		catch {
			$errorRecord = [System.Management.Automation.ErrorRecord]::new(
				$_.Exception,
				'DiskSelectionFailed',
				[System.Management.Automation.ErrorCategory]::ObjectNotFound,
				$null
			)
			$PSCmdlet.ThrowTerminatingError($errorRecord)
		}
	}

	if (-not $targetDisk -or $targetDisk.Count -eq 0) {
		$errorRecord = [System.Management.Automation.ErrorRecord]::new(
			[System.InvalidOperationException]::new('No selected deployment disk was found.'),
			'NoSelectedDisk',
			[System.Management.Automation.ErrorCategory]::ObjectNotFound,
			$null
		)
		$PSCmdlet.ThrowTerminatingError($errorRecord)
	}

	$targetDisk = $targetDisk[0]

	$targetDisk | Select-Object -Property DiskNumber, BusType, MediaType, PartitionStyle, @{Name = 'SizeGB'; Expression = { [math]::Round($_.Size / 1GB, 2) } } | Format-Table | Out-Host

	if (-not $Force.IsPresent) {
		Get-Help $MyInvocation.MyCommand.Name
		Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] No action taken. Re-run with -Force to perform a sanitizing clean all on Disk $($targetDisk.DiskNumber)."
		return
	}

	$diskPartScriptPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "osdcloud-cleanall-disk-$($targetDisk.DiskNumber).txt")
	[System.IO.File]::WriteAllLines(
		$diskPartScriptPath,
		@(
			"select disk $($targetDisk.DiskNumber)",
			'clean all',
			'exit'
		)
	)

	Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] DISKPART script: $diskPartScriptPath"
	Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] DISKPART> select disk $($targetDisk.DiskNumber)"
	Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] DISKPART> clean all"
	Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] DISKPART> exit"

	try {
		if ($PSCmdlet.ShouldProcess("Disk $($targetDisk.DiskNumber)", 'DiskPart clean all (sanitizing wipe)')) {
			$diskPartProcess = Start-Process -FilePath 'diskpart.exe' -ArgumentList "/s `"$diskPartScriptPath`"" -PassThru -Wait -NoNewWindow

			if ($diskPartProcess.ExitCode -ne 0) {
				$errorRecord = [System.Management.Automation.ErrorRecord]::new(
					[System.Exception]::new("diskpart.exe exited with code $($diskPartProcess.ExitCode)."),
					'DiskPartFailed',
					[System.Management.Automation.ErrorCategory]::InvalidResult,
					$targetDisk.DiskNumber
				)
				$PSCmdlet.ThrowTerminatingError($errorRecord)
			}

			Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Completed DiskPart clean all on Disk $($targetDisk.DiskNumber)"
		}
	}
	finally {
		if ([System.IO.File]::Exists($diskPartScriptPath)) {
			[System.IO.File]::Delete($diskPartScriptPath)
		}
	}
}
