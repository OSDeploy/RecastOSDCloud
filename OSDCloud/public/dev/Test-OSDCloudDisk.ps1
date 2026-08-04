function Test-OSDCloudDisk {
    <#
    .SYNOPSIS
        Tests local disk properties and health in WinPE.

    .DESCRIPTION
        Uses .NET Framework classes (System.Management and System.IO) to inspect
        physical disks, partitions, and logical volumes without relying on
        disk-focused PowerShell cmdlets. The function writes test progress and
        results to the console, includes partition sizes, exports a DiskPart
        rebuild script for each discovered disk, and returns $true only when all
        checks pass.

    .EXAMPLE
        Test-OSDCloudDisk

        Runs disk checks and returns True when all checks pass.

    .PARAMETER StrictWinPE
        Treat running outside WinPE as a failure instead of informational output.

    .PARAMETER HideInfo
        Suppresses informational output lines ([INFO]) while preserving pass/fail checks.

    .PARAMETER CriticalFreePercent
        Minimum required free space percentage. A value below this threshold is a failure.

    .PARAMETER LowFreePercent
        Low free space advisory threshold. A value below this threshold (but above
        CriticalFreePercent) is informational.

    .EXAMPLE
        Test-OSDCloudDisk -StrictWinPE

        Runs disk checks and fails immediately if not running in WinPE.

    .EXAMPLE
        Test-OSDCloudDisk -HideInfo -CriticalFreePercent 2 -LowFreePercent 8

        Runs checks with quieter output and custom free space thresholds.

    .EXAMPLE
        Test-OSDCloudDisk

        Exports DiskPart rebuild scripts to $env:Temp\diskpart-disk{disknumber}.txt.

    .OUTPUTS
        System.Boolean

    .NOTES
        This function is intended for WinPE diagnostics.
        Built to run in Windows PowerShell 5.1 (.NET Framework 4.6 compatible).
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter()]
        [switch]$StrictWinPE,

        [Parameter()]
        [switch]$HideInfo,

        [Parameter()]
        [ValidateRange(0, 100)]
        [double]$CriticalFreePercent = 1,

        [Parameter()]
        [ValidateRange(0, 100)]
        [double]$LowFreePercent = 5
    )

    $Error.Clear()
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"

    $tempPath = $env:Temp
    if ([string]::IsNullOrWhiteSpace($tempPath)) {
        $tempPath = [System.IO.Path]::GetTempPath()
    }

    if ($LowFreePercent -lt $CriticalFreePercent) {
        $message = "LowFreePercent ($LowFreePercent) must be greater than or equal to CriticalFreePercent ($CriticalFreePercent)."
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            [System.ArgumentException]::new($message),
            'InvalidFreeSpaceThreshold',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $LowFreePercent
        )
        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    $allTestsPassed = $true

    [System.Console]::WriteLine('')
    [System.Console]::WriteLine('=== OSDCloud Disk Health Test ===')
    [System.Console]::WriteLine("Timestamp: $([System.DateTime]::Now.ToString('s'))")

    if ($env:SystemDrive -eq 'X:') {
        [System.Console]::WriteLine('[PASS] Environment check: WinPE detected (SystemDrive = X:)')
    }
    else {
        if ($StrictWinPE) {
            [System.Console]::WriteLine('[FAIL] Environment check: StrictWinPE is set and SystemDrive is not X:')
            $allTestsPassed = $false
        }
        elseif (-not $HideInfo) {
            [System.Console]::WriteLine("[INFO] Environment check: running outside WinPE (SystemDrive = $env:SystemDrive); continuing with compatible checks")
        }
    }

    try {
        $diskSearcher = [System.Management.ManagementObjectSearcher]::new(
            'root\cimv2',
            'SELECT Index, Model, InterfaceType, Size, Status, Partitions, BytesPerSector FROM Win32_DiskDrive WHERE Size > 0'
        )
        $disks = @($diskSearcher.Get())

        if ($disks.Count -eq 0) {
            [System.Console]::WriteLine('[FAIL] Physical disk check: no local physical disks were detected')
            $allTestsPassed = $false
        }
        else {
            [System.Console]::WriteLine("[PASS] Physical disk check: detected $($disks.Count) physical disk(s)")
        }

        foreach ($disk in $disks) {
            $diskIndex = [int]$disk['Index']
            $diskModel = [string]$disk['Model']
            $interfaceType = [string]$disk['InterfaceType']
            $status = [string]$disk['Status']
            $sizeBytes = [int64]$disk['Size']
            $sizeGb = [Math]::Round(($sizeBytes / 1GB), 2)
            $declaredPartitionCount = 0
            $bytesPerSector = 0

            if ($null -ne $disk['Partitions']) {
                $declaredPartitionCount = [int]$disk['Partitions']
            }
            if ($null -ne $disk['BytesPerSector']) {
                $bytesPerSector = [int64]$disk['BytesPerSector']
            }

            [System.Console]::WriteLine('')
            [System.Console]::WriteLine("Disk ${diskIndex}: $diskModel")
            [System.Console]::WriteLine("  Interface: $interfaceType")
            [System.Console]::WriteLine("  Size (GB): $sizeGb")
            [System.Console]::WriteLine("  Status   : $status")
            [System.Console]::WriteLine("  Bytes/Sector: $bytesPerSector")

            if ([string]::IsNullOrWhiteSpace($diskModel)) {
                [System.Console]::WriteLine('  [FAIL] Disk model was not reported')
                $allTestsPassed = $false
            }
            else {
                [System.Console]::WriteLine('  [PASS] Disk model was reported')
            }

            if ([string]::IsNullOrWhiteSpace($interfaceType)) {
                [System.Console]::WriteLine('  [FAIL] Disk interface type was not reported')
                $allTestsPassed = $false
            }
            else {
                [System.Console]::WriteLine('  [PASS] Disk interface type was reported')
            }

            if ($sizeBytes -le 0) {
                [System.Console]::WriteLine('  [FAIL] Disk size is not valid')
                $allTestsPassed = $false
            }
            else {
                [System.Console]::WriteLine('  [PASS] Disk size is valid')
            }

            if ([string]::IsNullOrWhiteSpace($status) -or $status -eq 'OK') {
                [System.Console]::WriteLine('  [PASS] Disk status is healthy')
            }
            else {
                [System.Console]::WriteLine("  [FAIL] Disk status reports a problem: $status")
                $allTestsPassed = $false
            }

            if ($bytesPerSector -le 0) {
                [System.Console]::WriteLine('  [FAIL] Bytes per sector is not valid')
                $allTestsPassed = $false
            }
            elseif (($bytesPerSector -band ($bytesPerSector - 1)) -ne 0) {
                [System.Console]::WriteLine("  [FAIL] Bytes per sector value is unexpected: $bytesPerSector")
                $allTestsPassed = $false
            }
            else {
                [System.Console]::WriteLine('  [PASS] Bytes per sector value is valid')
            }

            $partitions = @()
            try {
                $partitions = @($disk.GetRelated('Win32_DiskPartition'))
            }
            catch {
                if (-not $HideInfo) {
                    [System.Console]::WriteLine('  [INFO] Falling back to Win32_DiskPartition query by DiskIndex')
                }

                try {
                    $partitionSearcher = [System.Management.ManagementObjectSearcher]::new(
                        'root\cimv2',
                        "SELECT Name, Status, Size, Type, Bootable, PrimaryPartition FROM Win32_DiskPartition WHERE DiskIndex = $diskIndex"
                    )
                    $partitions = @($partitionSearcher.Get())
                }
                catch {
                    [System.Console]::WriteLine("  [FAIL] Partition fallback query failed: $($_.Exception.Message)")
                    $allTestsPassed = $false
                    $partitions = @()
                }
            }

            $partitionCount = 0
            foreach ($partition in $partitions) {
                $partitionCount++
                $partitionName = [string]$partition['Name']
                $partitionStatus = [string]$partition['Status']
                $partitionSizeBytes = [int64]$partition['Size']
                $partitionSizeGb = [Math]::Round(($partitionSizeBytes / 1GB), 2)
                $partitionSizeMb = [Math]::Round(($partitionSizeBytes / 1MB), 0)
                $partitionType = [string]$partition['Type']
                $isBootable = [bool]$partition['Bootable']
                $isPrimary = [bool]$partition['PrimaryPartition']

                [System.Console]::WriteLine("  Partition: $partitionName")
                [System.Console]::WriteLine("    Type: $partitionType  Primary=$isPrimary  Bootable=$isBootable")
                [System.Console]::WriteLine("    Size: ${partitionSizeGb} GB (${partitionSizeMb} MB)")

                if ($partitionSizeBytes -le 0) {
                    [System.Console]::WriteLine('    [FAIL] Partition size is not valid')
                    $allTestsPassed = $false
                }
                else {
                    [System.Console]::WriteLine('    [PASS] Partition size is valid')
                }

                if (-not [string]::IsNullOrWhiteSpace($partitionStatus) -and $partitionStatus -ne 'OK') {
                    [System.Console]::WriteLine("    [FAIL] Partition status reports a problem: $partitionStatus")
                    $allTestsPassed = $false
                }
                else {
                    [System.Console]::WriteLine('    [PASS] Partition status is healthy')
                }

                if ([string]::IsNullOrWhiteSpace($partitionType)) {
                    [System.Console]::WriteLine('    [FAIL] Partition type was not reported')
                    $allTestsPassed = $false
                }
                else {
                    [System.Console]::WriteLine('    [PASS] Partition type was reported')
                }
            }

            if ($partitionCount -eq 0) {
                if (-not $HideInfo) {
                    [System.Console]::WriteLine('  [INFO] No partitions found on this disk (disk may be raw/uninitialized)')
                }
            }
            else {
                [System.Console]::WriteLine("  [PASS] Partition discovery: $partitionCount partition(s) found")
            }

            if ($declaredPartitionCount -gt 0 -and $declaredPartitionCount -ne $partitionCount) {
                [System.Console]::WriteLine("  [FAIL] Partition count mismatch: disk reports $declaredPartitionCount but association returned $partitionCount")
                $allTestsPassed = $false
            }
            else {
                [System.Console]::WriteLine('  [PASS] Partition count is consistent')
            }

            $diskPartScriptPath = [System.IO.Path]::Combine($tempPath, "diskpart-disk$diskIndex.txt")
            try {
                $diskPartScriptLines = @(
                    "rem OSDCloud rebuild script for disk $diskIndex generated $(Get-Date -Format s)",
                    "select disk $diskIndex",
                    'clean'
                )

                $hasGptPartitionType = $false
                $hasEfiPartition = $false
                $hasMsrPartition = $false
                foreach ($partition in $partitions) {
                    $partitionType = [string]$partition['Type']
                    if (-not [string]::IsNullOrWhiteSpace($partitionType) -and $partitionType.StartsWith('GPT:', [System.StringComparison]::OrdinalIgnoreCase)) {
                        $hasGptPartitionType = $true
                    }

                    if (-not [string]::IsNullOrWhiteSpace($partitionType) -and $partitionType -match 'System') {
                        $hasEfiPartition = $true
                    }

                    if (-not [string]::IsNullOrWhiteSpace($partitionType) -and ($partitionType -match 'Reserved' -or $partitionType -match 'MSR')) {
                        $hasMsrPartition = $true
                    }
                }

                if ($hasGptPartitionType) {
                    $diskPartScriptLines += 'convert gpt'
                }
                else {
                    $diskPartScriptLines += 'convert mbr'
                }

                foreach ($partition in $partitions) {
                    $partitionType = [string]$partition['Type']
                    $partitionSizeBytes = [int64]$partition['Size']
                    $partitionSizeMb = [int][Math]::Max(1, [Math]::Round(($partitionSizeBytes / 1MB), 0))
                    $isBootable = [bool]$partition['Bootable']
                    $isPrimary = [bool]$partition['PrimaryPartition']
                    $recoveryInferred = $false
                    $isRecoveryPartition = $false

                    if (-not [string]::IsNullOrWhiteSpace($partitionType) -and $partitionType -match 'Recovery') {
                        $isRecoveryPartition = $true
                    }
                    elseif ($hasGptPartitionType -and
                        (-not [string]::IsNullOrWhiteSpace($partitionType)) -and $partitionType -match 'Unknown' -and
                        $partitionSizeMb -ge 300 -and $partitionSizeMb -le 2048 -and
                        (-not $isBootable) -and (-not $isPrimary)) {
                        $isRecoveryPartition = $true
                        $recoveryInferred = $true
                    }

                    if (-not [string]::IsNullOrWhiteSpace($partitionType) -and $partitionType -match 'System') {
                        $diskPartScriptLines += "create partition efi size=$partitionSizeMb"
                    }
                    elseif (-not [string]::IsNullOrWhiteSpace($partitionType) -and ($partitionType -match 'Reserved' -or $partitionType -match 'MSR')) {
                        $diskPartScriptLines += "create partition msr size=$partitionSizeMb"
                    }
                    elseif ($isRecoveryPartition) {
                        $diskPartScriptLines += "create partition primary size=$partitionSizeMb"
                        if ($hasGptPartitionType) {
                            $diskPartScriptLines += 'set id=de94bba4-06d1-4d40-a16a-bfd50179d6ac'
                            $diskPartScriptLines += 'gpt attributes=0x8000000000000001'
                        }

                        if ($recoveryInferred -and (-not $HideInfo)) {
                            [System.Console]::WriteLine('  [INFO] Recovery partition inferred from GPT Unknown partition signature; exported with WinRE GUID and GPT attributes')
                        }
                    }
                    else {
                        $diskPartScriptLines += "create partition primary size=$partitionSizeMb"
                    }
                }

                if ($hasGptPartitionType -and $hasEfiPartition -and (-not $hasMsrPartition)) {
                    $insertIndex = -1
                    for ($lineIndex = 0; $lineIndex -lt $diskPartScriptLines.Count; $lineIndex++) {
                        if ($diskPartScriptLines[$lineIndex] -match '^create partition efi size=') {
                            $insertIndex = $lineIndex + 1
                            break
                        }
                    }

                    if ($insertIndex -gt 0) {
                        $diskPartScriptLines = @($diskPartScriptLines[0..($insertIndex - 1)] + 'create partition msr size=16' + $diskPartScriptLines[$insertIndex..($diskPartScriptLines.Count - 1)])
                    }
                    else {
                        $diskPartScriptLines += 'create partition msr size=16'
                    }

                    if (-not $HideInfo) {
                        [System.Console]::WriteLine('  [INFO] MSR partition was not detected in WMI; injected create partition msr size=16 into DiskPart script')
                    }
                }

                [System.IO.File]::WriteAllLines($diskPartScriptPath, $diskPartScriptLines)
                [System.Console]::WriteLine("  [PASS] Exported DiskPart rebuild script: $diskPartScriptPath")
                [System.Console]::WriteLine('  DiskPart script content:')
                foreach ($diskPartScriptLine in $diskPartScriptLines) {
                    [System.Console]::WriteLine("    $diskPartScriptLine")
                }
            }
            catch {
                [System.Console]::WriteLine("  [FAIL] Could not export DiskPart rebuild script: $($_.Exception.Message)")
                $allTestsPassed = $false
            }
        }

        $logicalDiskSearcher = [System.Management.ManagementObjectSearcher]::new(
            'root\cimv2',
            'SELECT DeviceID, FileSystem, Size, FreeSpace, Status, DriveType, VolumeDirty FROM Win32_LogicalDisk WHERE DriveType = 3'
        )
        $logicalDisks = @($logicalDiskSearcher.Get())

        [System.Console]::WriteLine('')
        [System.Console]::WriteLine('Logical fixed volumes:')
        if ($logicalDisks.Count -eq 0) {
            if (-not $HideInfo) {
                [System.Console]::WriteLine('  [INFO] No fixed logical volumes were found')
            }
        }

        foreach ($logicalDisk in $logicalDisks) {
            $deviceId = [string]$logicalDisk['DeviceID']
            $fileSystem = [string]$logicalDisk['FileSystem']
            $size = [int64]$logicalDisk['Size']
            $freeSpace = [int64]$logicalDisk['FreeSpace']
            $status = [string]$logicalDisk['Status']
            $volumeDirty = $false
            $freePercent = 0

            if ($null -ne $logicalDisk['VolumeDirty']) {
                $volumeDirty = [bool]$logicalDisk['VolumeDirty']
            }
            if ($size -gt 0) {
                $freePercent = [Math]::Round((100 * ($freeSpace / [double]$size)), 2)
            }

            [System.Console]::WriteLine("  Volume $deviceId  FS=$fileSystem  SizeGB=$([Math]::Round(($size / 1GB), 2))  FreeGB=$([Math]::Round(($freeSpace / 1GB), 2))")

            if ($size -le 0) {
                [System.Console]::WriteLine('    [FAIL] Logical volume size is not valid')
                $allTestsPassed = $false
            }
            else {
                [System.Console]::WriteLine('    [PASS] Logical volume size is valid')
            }

            if ([string]::IsNullOrWhiteSpace($fileSystem)) {
                [System.Console]::WriteLine('    [FAIL] Logical volume filesystem is not reported')
                $allTestsPassed = $false
            }
            else {
                [System.Console]::WriteLine('    [PASS] Logical volume filesystem is reported')
            }

            if ($freeSpace -lt 0 -or $freeSpace -gt $size) {
                [System.Console]::WriteLine('    [FAIL] Logical volume free space value is outside expected range')
                $allTestsPassed = $false
            }
            else {
                [System.Console]::WriteLine("    [PASS] Logical volume free space is valid ($freePercent%)")
            }

            if ($size -gt 0 -and $freePercent -lt $CriticalFreePercent) {
                [System.Console]::WriteLine("    [FAIL] Logical volume free space is critically low ($freePercent%)")
                $allTestsPassed = $false
            }
            elseif ($size -gt 0 -and $freePercent -lt $LowFreePercent) {
                if (-not $HideInfo) {
                    [System.Console]::WriteLine("    [INFO] Logical volume free space is low ($freePercent%)")
                }
            }
            else {
                [System.Console]::WriteLine('    [PASS] Logical volume free space threshold check passed')
            }

            if (-not [string]::IsNullOrWhiteSpace($status) -and $status -ne 'OK') {
                [System.Console]::WriteLine("    [FAIL] Logical volume status reports a problem: $status")
                $allTestsPassed = $false
            }
            else {
                [System.Console]::WriteLine('    [PASS] Logical volume status is healthy')
            }

            if ($volumeDirty) {
                [System.Console]::WriteLine('    [FAIL] Logical volume dirty bit is set (filesystem may need repair)')
                $allTestsPassed = $false
            }
            else {
                [System.Console]::WriteLine('    [PASS] Logical volume dirty bit is not set')
            }

            try {
                $driveInfo = [System.IO.DriveInfo]::new($deviceId)
                if ($driveInfo.IsReady) {
                    [System.Console]::WriteLine('    [PASS] DriveInfo reports the volume is ready')
                }
                else {
                    [System.Console]::WriteLine('    [FAIL] DriveInfo reports the volume is not ready')
                    $allTestsPassed = $false
                }

                if (-not $driveInfo.RootDirectory.Exists) {
                    [System.Console]::WriteLine('    [FAIL] Drive root is not accessible')
                    $allTestsPassed = $false
                }
                else {
                    [System.Console]::WriteLine('    [PASS] Drive root is accessible')
                }

                if ($size -gt 0) {
                    $sizeDelta = [Math]::Abs($driveInfo.TotalSize - $size)
                    $sizeDeltaPercent = [Math]::Round((100 * ($sizeDelta / [double]$size)), 2)
                    if ($sizeDeltaPercent -gt 5) {
                        if (-not $HideInfo) {
                            [System.Console]::WriteLine("    [INFO] DriveInfo size differs from WMI by $sizeDeltaPercent%")
                        }
                    }
                    else {
                        [System.Console]::WriteLine('    [PASS] DriveInfo size aligns with WMI')
                    }
                }
            }
            catch {
                [System.Console]::WriteLine("    [FAIL] DriveInfo check failed for ${deviceId}: $($_.Exception.Message)")
                $allTestsPassed = $false
            }
        }
    }
    catch {
        [System.Console]::WriteLine("[FAIL] Disk health test encountered an exception: $($_.Exception.Message)")
        $allTestsPassed = $false
    }

    [System.Console]::WriteLine('')
    if ($allTestsPassed) {
        [System.Console]::WriteLine('=== Result: PASS ===')
    }
    else {
        [System.Console]::WriteLine('=== Result: FAIL ===')
    }

    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End (Result: $allTestsPassed)"
    return $allTestsPassed
}
