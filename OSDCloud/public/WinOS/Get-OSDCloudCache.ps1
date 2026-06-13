function Get-OSDCloudCache {
    <#
    .SYNOPSIS
        Returns OSDCloud cache paths or cached content found on local file system drives.

    .DESCRIPTION
        Enumerates mounted file system drives and discovers OSDCloud cache content.
        Returns objects with Type, FullName, and SizeMB properties.

        If Type is omitted, returns discovered '<DriveLetter>:\OSDCloud' cache root
        folders as Type 'Cache'.

        Type values:
        - ESD: All .esd files under '<DriveLetter>:\OSDCloud\OS' recursively.
        - ISO: All .iso files under '<DriveLetter>:\OSDCloud\ISO' recursively.
        - DriverPacks: All .cab, .exe, .msi, and .zip files under
          '<DriveLetter>:\OSDCloud\DriverPacks' recursively.
        - Drivers: Immediate folders under '<DriveLetter>:\OSDCloud\Drivers' that
          contain at least one .inf file in any child folder.
        - WIM: All .wim files under '<DriveLetter>:\OSDCloud\WIM' recursively.
        - *: Includes all supported Type values.

    .PARAMETER Type
        Optional cache content selector.

        Supports one or more values. Use '*' to return all supported
        cache content types.

    .OUTPUTS
        System.Object[]. Objects with Type, FullName, and SizeMB.

    .EXAMPLE
        Get-OSDCloudCache

        Returns paths such as 'C:\OSDCloud' and 'D:\OSDCloud' when present.

    .EXAMPLE
        Get-OSDCloudCache -Type ESD

        Returns all .esd files under each discovered cache OS folder.

    .EXAMPLE
        Get-OSDCloudCache -Type ESD,DriverPacks

        Returns all .esd files and driver pack files from each discovered cache.

    .EXAMPLE
        Get-OSDCloudCache -Type *

        Returns all supported cache content types.
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter()]
        [ValidateSet('ESD', 'ISO', 'DriverPacks', 'Drivers', 'WIM', '*')]
        [string[]]$Type
    )

    $Error.Clear()
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"

    function Get-FileOnlySizeMB {
        param(
            [Parameter(Mandatory)]
            [string]$Path
        )

        if (-not (Test-Path -LiteralPath $Path)) {
            return 0
        }

        $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
        if (-not $item) {
            return 0
        }

        if ($item.PSIsContainer) {
            $totalBytes = (Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
            if ($null -eq $totalBytes) {
                $totalBytes = 0
            }
            return [math]::Round(($totalBytes / 1MB), 2)
        }

        return [math]::Round((([int64]$item.Length) / 1MB), 2)
    }

    function New-CacheResultObject {
        param(
            [Parameter(Mandatory)]
            [string]$ResultType,

            [Parameter(Mandatory)]
            [string]$ResultFullName
        )

        [PSCustomObject]@{
            Type     = $ResultType
            FullName = $ResultFullName
            SizeMB   = Get-FileOnlySizeMB -Path $ResultFullName
        }
    }

    $cachePaths = Get-PSDrive -PSProvider FileSystem |
        Where-Object { $_.Root -match '^[A-Z]:\\$' } |
        ForEach-Object {
            $driveRoot = [string]$_.Root
            $osdCloudPath = Join-Path -Path $driveRoot -ChildPath 'OSDCloud'

            if (Test-Path -LiteralPath $osdCloudPath) {
                $osdCloudPath
            }
        }

    $cachePaths = @($cachePaths | Sort-Object -Unique)

    if (-not $PSBoundParameters.ContainsKey('Type')) {
        $result = foreach ($cachePath in $cachePaths) {
            New-CacheResultObject -ResultType 'Cache' -ResultFullName $cachePath
        }

        $result = @($result | Sort-Object -Property FullName, Type -Unique | Sort-Object -Property FullName)
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Found $($result.Count) path(s)"
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
        return $result
    }

    $selectedTypes = @($Type | Sort-Object -Unique)
    if ($selectedTypes -contains '*') {
        $selectedTypes = @('ESD', 'ISO', 'DriverPacks', 'Drivers', 'WIM')
    }

    $result = foreach ($selectedType in $selectedTypes) {
        switch ($selectedType) {
            'ESD' {
                foreach ($cachePath in $cachePaths) {
                    $osPath = Join-Path -Path $cachePath -ChildPath 'OS'
                    if (Test-Path -LiteralPath $osPath) {
                        Get-ChildItem -LiteralPath $osPath -Recurse -File -Filter '*.esd' -ErrorAction SilentlyContinue |
                            ForEach-Object {
                                New-CacheResultObject -ResultType 'ESD' -ResultFullName ([string]$_.FullName)
                            }
                    }
                }
                break
            }
            'ISO' {
                foreach ($cachePath in $cachePaths) {
                    $isoPath = Join-Path -Path $cachePath -ChildPath 'ISO'
                    if (Test-Path -LiteralPath $isoPath) {
                        Get-ChildItem -LiteralPath $isoPath -Recurse -File -Filter '*.iso' -ErrorAction SilentlyContinue |
                            ForEach-Object {
                                New-CacheResultObject -ResultType 'ISO' -ResultFullName ([string]$_.FullName)
                            }
                    }
                }
                break
            }
            'DriverPacks' {
                foreach ($cachePath in $cachePaths) {
                    $driverPacksPath = Join-Path -Path $cachePath -ChildPath 'DriverPacks'
                    if (Test-Path -LiteralPath $driverPacksPath) {
                        Get-ChildItem -LiteralPath $driverPacksPath -Recurse -File -ErrorAction SilentlyContinue |
                            Where-Object { $_.Extension -in @('.cab', '.exe', '.msi', '.zip') } |
                            ForEach-Object {
                                New-CacheResultObject -ResultType 'DriverPacks' -ResultFullName ([string]$_.FullName)
                            }
                    }
                }
                break
            }
            'Drivers' {
                foreach ($cachePath in $cachePaths) {
                    $driversPath = Join-Path -Path $cachePath -ChildPath 'Drivers'
                    if (Test-Path -LiteralPath $driversPath) {
                        Get-ChildItem -LiteralPath $driversPath -Directory -ErrorAction SilentlyContinue |
                            Where-Object {
                                @(Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Filter '*.inf' -ErrorAction SilentlyContinue).Count -gt 0
                            } |
                            ForEach-Object {
                                New-CacheResultObject -ResultType 'Drivers' -ResultFullName ([string]$_.FullName)
                            }
                    }
                }
                break
            }
            'WIM' {
                foreach ($cachePath in $cachePaths) {
                    $wimPath = Join-Path -Path $cachePath -ChildPath 'WIM'
                    if (Test-Path -LiteralPath $wimPath) {
                        Get-ChildItem -LiteralPath $wimPath -Recurse -File -Filter '*.wim' -ErrorAction SilentlyContinue |
                            ForEach-Object {
                                New-CacheResultObject -ResultType 'WIM' -ResultFullName ([string]$_.FullName)
                            }
                    }
                }
                break
            }
        }
    }

    $result = @($result | Sort-Object -Property FullName, Type -Unique | Sort-Object -Property FullName)
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Found $($result.Count) path(s)"
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"

    return $result
}
