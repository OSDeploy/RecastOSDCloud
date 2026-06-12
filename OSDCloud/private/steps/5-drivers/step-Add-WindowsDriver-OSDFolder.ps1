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

    $expandRoot = "C:\Windows\Temp\osdcloud-osdfolder-expand"

    foreach ($drive in $drives) {
        #region OSDManufacturer — name starts with OSDManufacturer value
        if (-not [string]::IsNullOrWhiteSpace($osdManufacturer)) {
            $parentPath = "$($drive.Name):\OSDCloud\DriverPacks\OSDManufacturer"
            if (Test-Path -Path $parentPath) {
                # Folder
                $matchedDirs = Get-ChildItem -Path $parentPath -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "$osdManufacturer*" }
                foreach ($dir in $matchedDirs) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDManufacturer folder match: $($dir.FullName)"
                    Add-WindowsDriver -Path $OfflinePath -Driver $dir.FullName -Recurse -ForceUnsigned `
                        -LogPath "$LogPath\dism-add-windowsdriver-osdfolder.log" `
                        -ErrorAction SilentlyContinue | Out-Null
                }
                # Zip
                $matchedZips = Get-ChildItem -Path $parentPath -File -Filter "*.zip" -ErrorAction SilentlyContinue |
                    Where-Object { $_.BaseName -like "$osdManufacturer*" }
                foreach ($zip in $matchedZips) {
                    $expandPath = Join-Path -Path $expandRoot -ChildPath $zip.BaseName
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDManufacturer zip match: $($zip.FullName)"
                    Expand-Archive -Path $zip.FullName -DestinationPath $expandPath -Force
                    Add-WindowsDriver -Path $OfflinePath -Driver $expandPath -Recurse -ForceUnsigned `
                        -LogPath "$LogPath\dism-add-windowsdriver-osdfolder.log" `
                        -ErrorAction SilentlyContinue | Out-Null
                    Remove-Item -Path $expandPath -Recurse -Force -ErrorAction SilentlyContinue
                }
                # PS1
                $matchedScripts = Get-ChildItem -Path $parentPath -File -Filter "*.ps1" -ErrorAction SilentlyContinue |
                    Where-Object { $_.BaseName -like "$osdManufacturer*" }
                foreach ($script in $matchedScripts) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDManufacturer ps1 match: $($script.FullName)"
                    & $script.FullName
                }
            }
        }
        #endregion

        #region OSDModel — name contains OSDModel value
        if (-not [string]::IsNullOrWhiteSpace($osdModel)) {
            $parentPath = "$($drive.Name):\OSDCloud\DriverPacks\OSDModel"
            if (Test-Path -Path $parentPath) {
                # Folder
                $matchedDirs = Get-ChildItem -Path $parentPath -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "*$osdModel*" }
                foreach ($dir in $matchedDirs) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDModel folder match: $($dir.FullName)"
                    Add-WindowsDriver -Path $OfflinePath -Driver $dir.FullName -Recurse -ForceUnsigned `
                        -LogPath "$LogPath\dism-add-windowsdriver-osdfolder.log" `
                        -ErrorAction SilentlyContinue | Out-Null
                }
                # Zip
                $matchedZips = Get-ChildItem -Path $parentPath -File -Filter "*.zip" -ErrorAction SilentlyContinue |
                    Where-Object { $_.BaseName -like "*$osdModel*" }
                foreach ($zip in $matchedZips) {
                    $expandPath = Join-Path -Path $expandRoot -ChildPath $zip.BaseName
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDModel zip match: $($zip.FullName)"
                    Expand-Archive -Path $zip.FullName -DestinationPath $expandPath -Force
                    Add-WindowsDriver -Path $OfflinePath -Driver $expandPath -Recurse -ForceUnsigned `
                        -LogPath "$LogPath\dism-add-windowsdriver-osdfolder.log" `
                        -ErrorAction SilentlyContinue | Out-Null
                    Remove-Item -Path $expandPath -Recurse -Force -ErrorAction SilentlyContinue
                }
                # PS1
                $matchedScripts = Get-ChildItem -Path $parentPath -File -Filter "*.ps1" -ErrorAction SilentlyContinue |
                    Where-Object { $_.BaseName -like "*$osdModel*" }
                foreach ($script in $matchedScripts) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDModel ps1 match: $($script.FullName)"
                    & $script.FullName
                }
            }
        }
        #endregion

        #region OSDProduct — name contains OSDProduct value
        if (-not [string]::IsNullOrWhiteSpace($osdProduct)) {
            $parentPath = "$($drive.Name):\OSDCloud\DriverPacks\OSDProduct"
            if (Test-Path -Path $parentPath) {
                # Folder
                $matchedDirs = Get-ChildItem -Path $parentPath -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "*$osdProduct*" }
                foreach ($dir in $matchedDirs) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDProduct folder match: $($dir.FullName)"
                    Add-WindowsDriver -Path $OfflinePath -Driver $dir.FullName -Recurse -ForceUnsigned `
                        -LogPath "$LogPath\dism-add-windowsdriver-osdfolder.log" `
                        -ErrorAction SilentlyContinue | Out-Null
                }
                # Zip
                $matchedZips = Get-ChildItem -Path $parentPath -File -Filter "*.zip" -ErrorAction SilentlyContinue |
                    Where-Object { $_.BaseName -like "*$osdProduct*" }
                foreach ($zip in $matchedZips) {
                    $expandPath = Join-Path -Path $expandRoot -ChildPath $zip.BaseName
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDProduct zip match: $($zip.FullName)"
                    Expand-Archive -Path $zip.FullName -DestinationPath $expandPath -Force
                    Add-WindowsDriver -Path $OfflinePath -Driver $expandPath -Recurse -ForceUnsigned `
                        -LogPath "$LogPath\dism-add-windowsdriver-osdfolder.log" `
                        -ErrorAction SilentlyContinue | Out-Null
                    Remove-Item -Path $expandPath -Recurse -Force -ErrorAction SilentlyContinue
                }
                # PS1
                $matchedScripts = Get-ChildItem -Path $parentPath -File -Filter "*.ps1" -ErrorAction SilentlyContinue |
                    Where-Object { $_.BaseName -like "*$osdProduct*" }
                foreach ($script in $matchedScripts) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDProduct ps1 match: $($script.FullName)"
                    & $script.FullName
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
