function step-Add-WindowsDriver-OSDFolder {
    [CmdletBinding()]
    param ()
    #=================================================
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message
    $Step = $global:OSDCloudCurrentStep
    #=================================================
    $LogPath = "C:\Windows\Temp\osdcloud-logs"
    $OfflinePath = "C:\"

    $osdManufacturer = $global:OSDCloudDevice.OSDManufacturer
    $osdModel        = $global:OSDCloudDevice.OSDModel
    $osdProduct      = $global:OSDCloudDevice.OSDProduct

    if (-not (Test-Path -Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }

    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        #region OSDManufacturer — folder name starts with OSDManufacturer value
        if (-not [string]::IsNullOrWhiteSpace($osdManufacturer)) {
            $parentPath = "$($drive.Name):\OSDCloud\DriverPacks\OSDManufacturer"
            if (Test-Path -Path $parentPath) {
                $matchedDirs = Get-ChildItem -Path $parentPath -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "$osdManufacturer*" }
                foreach ($dir in $matchedDirs) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDManufacturer match: $($dir.FullName)"
                    Add-WindowsDriver -Path $OfflinePath -Driver $dir.FullName -Recurse -ForceUnsigned `
                        -LogPath "$LogPath\dism-add-windowsdriver-osdfolder.log" `
                        -ErrorAction SilentlyContinue | Out-Null
                }
            }
        }
        #endregion

        #region OSDModel — folder name contains OSDModel value
        if (-not [string]::IsNullOrWhiteSpace($osdModel)) {
            $parentPath = "$($drive.Name):\OSDCloud\DriverPacks\OSDModel"
            if (Test-Path -Path $parentPath) {
                $matchedDirs = Get-ChildItem -Path $parentPath -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "*$osdModel*" }
                foreach ($dir in $matchedDirs) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDModel match: $($dir.FullName)"
                    Add-WindowsDriver -Path $OfflinePath -Driver $dir.FullName -Recurse -ForceUnsigned `
                        -LogPath "$LogPath\dism-add-windowsdriver-osdfolder.log" `
                        -ErrorAction SilentlyContinue | Out-Null
                }
            }
        }
        #endregion

        #region OSDProduct — folder name contains OSDProduct value
        if (-not [string]::IsNullOrWhiteSpace($osdProduct)) {
            $parentPath = "$($drive.Name):\OSDCloud\DriverPacks\OSDProduct"
            if (Test-Path -Path $parentPath) {
                $matchedDirs = Get-ChildItem -Path $parentPath -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "*$osdProduct*" }
                foreach ($dir in $matchedDirs) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDProduct match: $($dir.FullName)"
                    Add-WindowsDriver -Path $OfflinePath -Driver $dir.FullName -Recurse -ForceUnsigned `
                        -LogPath "$LogPath\dism-add-windowsdriver-osdfolder.log" `
                        -ErrorAction SilentlyContinue | Out-Null
                }
            }
        }
        #endregion
    }
    #=================================================
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
