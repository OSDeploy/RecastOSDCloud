<#!
.SYNOPSIS
    Interactive picker for OSDCloud operating system catalog entries using WPF UI (Fluent Design).
#>
[CmdletBinding()]
param()
#================================================
Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase
# Load Wpf.Ui.dll if not already loaded (handles the case where the module did not pre-load it)
try {
    if (!([System.Management.Automation.PSTypeName]'Wpf.Ui.Controls.Button').Type) {
        $moduleBase = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            Add-Type -Path (Join-Path $moduleBase 'types\wpfui\net481\Wpf.Ui.dll')
        } else {
            Add-Type -Path (Join-Path $moduleBase 'types\wpfui\net6.0-windows\Wpf.Ui.dll')
        }
    }
} catch {
    Write-Warning "[MainWindow.ps1] Could not load Wpf.Ui.dll: $_"
}
#================================================
# Variables
$deviceBiosReleaseDate       = $global:OSDCloudDevice.BiosReleaseDate
$deviceBiosVersion           = $global:OSDCloudDevice.BiosVersion
$deviceOSDManufacturer       = $global:OSDCloudDevice.OSDManufacturer
$deviceOSDModel              = $global:OSDCloudDevice.OSDModel
$deviceOSDProduct            = $global:OSDCloudDevice.OSDProduct
$deviceComputerSystemSKU     = $global:OSDCloudDevice.ComputerSystemSKU
$deviceIsAutopilotSpec       = $global:OSDCloudDevice.IsAutopilotSpec
$deviceIsTpmSpec             = $global:OSDCloudDevice.IsTpmSpec
$deviceSerialNumber          = $global:OSDCloudDevice.SerialNumber
$deviceUUID                  = $global:OSDCloudDevice.UUID
$deviceHardwareHash          = $global:OSDCloudDevice.HardwareHash
$getOSDCloudModuleVersion    = Get-OSDCloudModuleVersion
#================================================
# WPFUI Fluent theme initialization
# Ensure a WPF Application singleton exists (WPFUI requires it for theme resource resolution)
if (-not [System.Windows.Application]::Current) {
    try {
        $null = [System.Windows.Application]::new()
    } catch {
        Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] Could not create WPF Application: $_"
    }
}

# Merge WPFUI theme and control resource dictionaries into the Application resources.
# ThemesDictionary and ControlsDictionary are WPFUI markup types that resolve their
# own pack URIs, so no hard-coded Source URI is required here.
if ([System.Windows.Application]::Current) {
    try {
        $themeDict    = [Wpf.Ui.Markup.ThemesDictionary]::new()
        $themeDict.Theme = [Wpf.Ui.Appearance.ThemeType]::Light
        $controlsDict = [Wpf.Ui.Markup.ControlsDictionary]::new()
        $appResources = [System.Windows.Application]::Current.Resources
        $appResources.MergedDictionaries.Add($themeDict)
        $appResources.MergedDictionaries.Add($controlsDict)
        Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] WPFUI theme merged successfully"
    } catch {
        Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] WPFUI theme merge skipped: $_"
    }
}
#================================================
# XAML
$xamlfile = Get-Item -Path "$PSScriptRoot\MainWindow.xaml"
$xaml = Get-Content $xamlfile.FullName

$stringReader = [System.IO.StringReader]::new($xaml)
$xmlReader    = [System.Xml.XmlReader]::Create($stringReader)
$window       = [Windows.Markup.XamlReader]::Load($xmlReader)
#================================================
# Window Title
$deviceTitleParts = @()
if (-not [string]::IsNullOrWhiteSpace($getOSDCloudModuleVersion)) {
    $deviceTitleParts += $getOSDCloudModuleVersion
}
if ($deviceTitleParts.Count -gt 0) {
    $window.Title = "OSDCloud version $($deviceTitleParts -join ' - ')"
}
#================================================
# Logo
$logoImage = $window.FindName('LogoImage')
if ($logoImage) {
    $logoImage.Source = "$PSScriptRoot\logo.png"
}
#================================================
# Navigation panel switching
$NavListBox      = $window.FindName('NavListBox')
$DevicePanel     = $window.FindName('DevicePanel')
$DriversPanel    = $window.FindName('DriversPanel')
$DiskPanel       = $window.FindName('DiskPanel')
$DeploymentPanel = $window.FindName('DeploymentPanel')
$StepsPanel      = $window.FindName('StepsPanel')
$PrivacyPanel    = $window.FindName('PrivacyPanel')

$NavListBox.SelectedIndex = 0
$NavListBox.Add_SelectionChanged({
    $tag = if ($NavListBox.SelectedItem) { [string]$NavListBox.SelectedItem.Tag } else { 'Deployment' }
    $DevicePanel.Visibility     = if ($tag -eq 'Device')     { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    $DriversPanel.Visibility    = if ($tag -eq 'Drivers')    { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    $DiskPanel.Visibility       = if ($tag -eq 'Disk')       { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    $DeploymentPanel.Visibility = if ($tag -eq 'Deployment') { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    $StepsPanel.Visibility      = if ($tag -eq 'Steps')      { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    $PrivacyPanel.Visibility    = if ($tag -eq 'Privacy')    { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
})
#================================================
# Menu Items
$RunCmdPrompt    = $window.FindName("RunCmdPrompt")
$RunPowerShell   = $window.FindName("RunPowerShell")
$RunPwsh         = $window.FindName("RunPwsh")
$LogsMenuItem    = $window.FindName("LogsMenuItem")
$WMIMenuItem     = $window.FindName("WMIMenuItem")

$RunCmdPrompt.Add_Click({
    try {
        Start-Process -FilePath "cmd.exe"
    } catch {
        [System.Windows.MessageBox]::Show("Failed to open CMD Prompt: $($_.Exception.Message)", "Error", "OK", "Error") | Out-Null
    }
})

$RunPowerShell.Add_Click({
    try {
        Start-Process -FilePath "powershell.exe"
    } catch {
        [System.Windows.MessageBox]::Show("Failed to open PowerShell: $($_.Exception.Message)", "Error", "OK", "Error") | Out-Null
    }
})

if ($RunPwsh) {
    $pwshCommand = Get-Command -Name 'pwsh.exe' -ErrorAction SilentlyContinue
    if ($pwshCommand) {
        $script:PwshPath = $pwshCommand.Source
        $RunPwsh.Visibility = [System.Windows.Visibility]::Visible
        $RunPwsh.Add_Click({
            try {
                Start-Process -FilePath $script:PwshPath
            } catch {
                [System.Windows.MessageBox]::Show("Failed to open PowerShell 7: $($_.Exception.Message)", "Error", "OK", "Error") | Out-Null
            }
        })
    } else {
        $RunPwsh.Visibility = [System.Windows.Visibility]::Collapsed
    }
}

function Add-NoLogsMenuEntry {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.MenuItem]$MenuItem
    )

    $noLogsItem = [System.Windows.Controls.MenuItem]::new()
    $noLogsItem.Header = 'No logs found'
    $noLogsItem.IsEnabled = $false
    $MenuItem.Items.Add($noLogsItem) | Out-Null
}

function Set-LogsMenuItems {
    $LogsMenuItem.Items.Clear()

    $logsRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'osdcloud-logs'
    if (-not (Test-Path -LiteralPath $logsRoot)) {
        Add-NoLogsMenuEntry -MenuItem $LogsMenuItem
        return
    }

    $logFiles = Get-ChildItem -LiteralPath $logsRoot -File -ErrorAction SilentlyContinue | Sort-Object -Property Name
    $logFiles = $logFiles | Where-Object { $_.Name -NotLike "Win32_*.txt" }
    if (-not $logFiles) {
        Add-NoLogsMenuEntry -MenuItem $LogsMenuItem
        return
    }

    foreach ($logFile in $logFiles) {
        $logMenuItem = [System.Windows.Controls.MenuItem]::new()
        $logMenuItem.Header = $logFile.Name -replace '_', '__'
        $logMenuItem.Tag = $logFile.FullName

        $logMenuItem.Add_Click({
            param($menuItem, $clickArgs)
            $logPath = [string]$menuItem.Tag
            if (-not (Test-Path -LiteralPath $logPath)) {
                [System.Windows.MessageBox]::Show('Log file not found.', 'Open Log', 'OK', 'Warning') | Out-Null
                return
            }
            try {
                Start-Process -FilePath 'notepad.exe' -ArgumentList @("`"$logPath`"") -ErrorAction Stop
            } catch {
                [System.Windows.MessageBox]::Show("Failed to open log: $($_.Exception.Message)", 'Open Log', 'OK', 'Error') | Out-Null
            }
        })

        $LogsMenuItem.Items.Add($logMenuItem) | Out-Null
    }
}
Set-LogsMenuItems

function Set-WMIMenuItems {
    $WMIMenuItem.Items.Clear()

    $logsRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'osdcloud-logs'
    if (-not (Test-Path -LiteralPath $logsRoot)) {
        Add-NoLogsMenuEntry -MenuItem $WMIMenuItem
        return
    }

    $logFiles = Get-ChildItem -LiteralPath $logsRoot -File -ErrorAction SilentlyContinue | Sort-Object -Property Name
    $logFiles = $logFiles | Where-Object { $_.Name -Like "Win32_*.txt" }
    if (-not $logFiles) {
        Add-NoLogsMenuEntry -MenuItem $WMIMenuItem
        return
    }

    foreach ($logFile in $logFiles) {
        $logMenuItem = [System.Windows.Controls.MenuItem]::new()
        $logMenuItem.Header = $logFile.Name -replace '_', '__'
        $logMenuItem.Tag = $logFile.FullName

        $logMenuItem.Add_Click({
            param($menuItem, $clickArgs)
            $logPath = [string]$menuItem.Tag
            if (-not (Test-Path -LiteralPath $logPath)) {
                [System.Windows.MessageBox]::Show('Log file not found.', 'Open Log', 'OK', 'Warning') | Out-Null
                return
            }
            try {
                Start-Process -FilePath 'notepad.exe' -ArgumentList @("`"$logPath`"") -ErrorAction Stop
            } catch {
                [System.Windows.MessageBox]::Show("Failed to open log: $($_.Exception.Message)", 'Open Log', 'OK', 'Error') | Out-Null
            }
        })

        $WMIMenuItem.Items.Add($logMenuItem) | Out-Null
    }
}
Set-WMIMenuItems
#================================================
# Task Sequence
$TaskSequenceCombo    = $window.FindName("TaskSequenceCombo")
$taskSequenceFlows    = $global:OSDCloudDeploy.Flows.Name
if ($null -eq $taskSequenceFlows) { $taskSequenceFlows = @() }
$TaskSequenceCombo.ItemsSource   = $taskSequenceFlows
$TaskSequenceCombo.SelectedIndex = 0
$TaskSequenceStepsGrid = $window.FindName("TaskSequenceStepsGrid")
$script:CurrentTaskSequenceName = [string]$TaskSequenceCombo.SelectedItem

$TaskSequenceStepsGrid.CanUserSortColumns = $false
$TaskSequenceStepsGrid.Add_Sorting({
    param($eventSource, $sortArgs)
    $sortArgs.Handled = $true
    $eventSource.Items.SortDescriptions.Clear()
})

function New-StepCheckBoxColumn {
    param(
        [Parameter(Mandatory)]
        [string]$PropertyName
    )

    $binding = [System.Windows.Data.Binding]::new($PropertyName)
    $binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
    $binding.UpdateSourceTrigger = [System.Windows.Data.UpdateSourceTrigger]::PropertyChanged
    $binding.TargetNullValue = $false
    $binding.FallbackValue = $false

    $elementStyle = [System.Windows.Style]::new([System.Windows.Controls.CheckBox])
    $elementStyle.Setters.Add([System.Windows.Setter]::new([System.Windows.Controls.CheckBox]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center))
    $elementStyle.Setters.Add([System.Windows.Setter]::new([System.Windows.Controls.CheckBox]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center))
    $elementStyle.Setters.Add([System.Windows.Setter]::new([System.Windows.Controls.CheckBox]::IsThreeStateProperty, $false))

    $checkboxColumn = [System.Windows.Controls.DataGridCheckBoxColumn]::new()
    $checkboxColumn.Header = $PropertyName
    $checkboxColumn.Binding = $binding
    $checkboxColumn.ElementStyle = $elementStyle
    $checkboxColumn.EditingElementStyle = $elementStyle
    $checkboxColumn.IsReadOnly = $false
    $checkboxColumn.CanUserSort = $false
    $checkboxColumn.Width = [System.Windows.Controls.DataGridLength]::new(44)
    return $checkboxColumn
}

function Save-TaskSequenceSteps {
    param(
        [Parameter(Mandatory)]
        [string]$TaskSequenceName,

        [Parameter()]
        $Steps
    )

    if ([string]::IsNullOrWhiteSpace($TaskSequenceName)) {
        return
    }

    $workflowTaskObject = $global:OSDCloudDeploy.Flows | Where-Object { $_.Name -eq $TaskSequenceName } | Select-Object -First 1
    if (-not $workflowTaskObject) {
        return
    }

    if ($Steps) {
        $stepsArray = @($Steps)
        foreach ($step in $stepsArray) {
            if (-not (Get-Member -InputObject $step -Name 'skip' -ErrorAction SilentlyContinue)) {
                $step | Add-Member -MemberType NoteProperty -Name 'skip' -Value $false
            }
            if (-not (Get-Member -InputObject $step -Name 'debug' -ErrorAction SilentlyContinue)) {
                $step | Add-Member -MemberType NoteProperty -Name 'debug' -Value $false
            }
            if (-not (Get-Member -InputObject $step -Name 'pause' -ErrorAction SilentlyContinue)) {
                $step | Add-Member -MemberType NoteProperty -Name 'pause' -Value $false
            }
            if (-not (Get-Member -InputObject $step -Name 'verbose' -ErrorAction SilentlyContinue)) {
                $step | Add-Member -MemberType NoteProperty -Name 'verbose' -Value $false
            }
        }
        $workflowTaskObject.steps = $stepsArray
    } else {
        $workflowTaskObject.steps = @()
    }
}

$TaskSequenceStepsGrid.Add_AutoGeneratingColumn({
    param($eventSource, $columnArgs)

    $columnArgs.Column.CanUserSort = $false

    if (@('debug', 'verbose', 'testinfullos') -icontains $columnArgs.PropertyName) {
        $columnArgs.Cancel = $true
        return
    }

    if ($columnArgs.PropertyName -ieq 'skip' -or $columnArgs.PropertyName -ieq 'pause') {
        $columnArgs.Column = New-StepCheckBoxColumn -PropertyName $columnArgs.PropertyName
        return
    }

    if ($columnArgs.PropertyName -ieq 'command') {
        $binding = [System.Windows.Data.Binding]::new($columnArgs.PropertyName)
        $binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
        $binding.UpdateSourceTrigger = [System.Windows.Data.UpdateSourceTrigger]::PropertyChanged

        $columnArgs.Column.IsReadOnly = $false
        $columnArgs.Column.CanUserSort = $false
        if ($columnArgs.Column -is [System.Windows.Controls.DataGridTextColumn]) {
            $columnArgs.Column.Binding = $binding
        }
        return
    }

    if ($columnArgs.PropertyName -ieq 'name') {
        $binding = [System.Windows.Data.Binding]::new($columnArgs.PropertyName)
        $binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
        $binding.UpdateSourceTrigger = [System.Windows.Data.UpdateSourceTrigger]::PropertyChanged

        $columnArgs.Column.IsReadOnly = $false
        $columnArgs.Column.CanUserSort = $false
        if ($columnArgs.Column -is [System.Windows.Controls.DataGridTextColumn]) {
            $columnArgs.Column.Binding = $binding
        }
        return
    }

    $columnArgs.Column.IsReadOnly = $true
    $columnArgs.Column.CanUserSort = $false
})

$TaskSequenceStepsGrid.Add_AutoGeneratedColumns({
    param($eventSource, $autoGeneratedColumnsArgs)

    $skipColumn = $eventSource.Columns | Where-Object { [string]$_.Header -ieq 'skip' } | Select-Object -First 1
    if ($skipColumn) {
        $skipColumn.DisplayIndex = 0
    }
})

function Update-TaskSequenceSteps {
    $selectedTaskSequence = [string]$TaskSequenceCombo.SelectedItem
    if ([string]::IsNullOrWhiteSpace($selectedTaskSequence)) {
        $TaskSequenceStepsGrid.ItemsSource = $null
        return
    }

    $workflowTaskObject = $global:OSDCloudDeploy.Flows | Where-Object { $_.Name -eq $selectedTaskSequence } | Select-Object -First 1

    if ($workflowTaskObject -and $workflowTaskObject.steps) {
        $steps = $workflowTaskObject.steps
        foreach ($step in $steps) {
            if (-not (Get-Member -InputObject $step -Name 'skip' -ErrorAction SilentlyContinue)) {
                $step | Add-Member -MemberType NoteProperty -Name 'skip' -Value $false
            }
            if (-not (Get-Member -InputObject $step -Name 'debug' -ErrorAction SilentlyContinue)) {
                $step | Add-Member -MemberType NoteProperty -Name 'debug' -Value $false
            }
            if (-not (Get-Member -InputObject $step -Name 'pause' -ErrorAction SilentlyContinue)) {
                $step | Add-Member -MemberType NoteProperty -Name 'pause' -Value $false
            }
            if (-not (Get-Member -InputObject $step -Name 'verbose' -ErrorAction SilentlyContinue)) {
                $step | Add-Member -MemberType NoteProperty -Name 'verbose' -Value $false
            }
        }

        $TaskSequenceStepsGrid.Items.SortDescriptions.Clear()
        $TaskSequenceStepsGrid.ItemsSource = $steps
        $TaskSequenceStepsGrid.Items.SortDescriptions.Clear()
    } else {
        $TaskSequenceStepsGrid.ItemsSource = $null
    }
}

$TaskSequenceCombo.Add_SelectionChanged({
    if ($SummaryTaskSequenceText) {
        $value = [string]$TaskSequenceCombo.SelectedItem
        $SummaryTaskSequenceText.Text = if (-not [string]::IsNullOrWhiteSpace($value)) { $value } else { 'Not selected' }
    }
    Save-TaskSequenceSteps -TaskSequenceName $script:CurrentTaskSequenceName -Steps $TaskSequenceStepsGrid.ItemsSource
    $script:CurrentTaskSequenceName = [string]$TaskSequenceCombo.SelectedItem
    Update-TaskSequenceSteps
})
Update-TaskSequenceSteps
#================================================
# Local ISO Values
function Get-LocalIsoFile {
    $localIsoFiles = @(
        Get-OSDCloudCache -Type ISO -ErrorAction SilentlyContinue |
            Where-Object { $_.Type -eq 'ISO' -and -not [string]::IsNullOrWhiteSpace([string]$_.FullName) }
    )

    return @($localIsoFiles | Sort-Object -Property FullName -Unique)
}

function Get-DriverPackCacheFile {
    param(
        [Parameter()]
        $DriverPackObject,

        [Parameter()]
        [System.Object[]]$CacheItems
    )

    if (-not $DriverPackObject -or -not $CacheItems) {
        return $null
    }

    $candidateFileNames = @()

    $fileName = [string]$DriverPackObject.FileName
    if (-not [string]::IsNullOrWhiteSpace($fileName)) {
        $candidateFileNames += [System.IO.Path]::GetFileName($fileName)
    }

    $url = [string]$DriverPackObject.Url
    if (-not [string]::IsNullOrWhiteSpace($url)) {
        try {
            $candidateFileNames += [System.IO.Path]::GetFileName(([System.Uri]$url).AbsolutePath)
        } catch {
            $candidateFileNames += [System.IO.Path]::GetFileName($url)
        }
    }

    $candidateFileNames = @(
        $candidateFileNames |
            Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } |
            Sort-Object -Unique
    )

    if (-not $candidateFileNames) {
        return $null
    }

    $exactFileName = [string]$DriverPackObject.FileName
    if (-not [string]::IsNullOrWhiteSpace($exactFileName)) {
        $matchedExact = $CacheItems | Where-Object {
            [System.IO.Path]::GetFileName([string]$_.FullName) -ieq [System.IO.Path]::GetFileName($exactFileName)
        } | Select-Object -First 1

        if ($matchedExact) {
            return $matchedExact
        }
    }

    return $CacheItems | Where-Object {
        $cacheFileName = [System.IO.Path]::GetFileName([string]$_.FullName)
        $candidateFileNames -icontains $cacheFileName
    } | Select-Object -First 1
}

function Get-DriverPackCacheItems {
    return @(
        Get-OSDCloudCache -Type DriverPacks -ErrorAction SilentlyContinue |
            Where-Object { $_.Type -eq 'DriverPacks' -and -not [string]::IsNullOrWhiteSpace([string]$_.FullName) }
    )
}

function Test-IsUsbDriveRoot {
    param(
        [Parameter(Mandatory)]
        [string]$DriveRoot
    )

    if ($DriveRoot -notmatch '^[A-Z]:\\$') {
        return $false
    }

    $driveLetter = $DriveRoot.Substring(0, 1)

    try {
        $partition = Get-Partition -DriveLetter $driveLetter -ErrorAction Stop | Select-Object -First 1
        if ($partition) {
            $disk = Get-Disk -Number $partition.DiskNumber -ErrorAction SilentlyContinue
            if ($disk -and [string]$disk.BusType -ieq 'USB') {
                return $true
            }
        }
    } catch {
    }

    try {
        $volume = Get-Volume -DriveLetter $driveLetter -ErrorAction Stop
        if ($volume -and ([string]$volume.DriveType -ieq 'Removable')) {
            return $true
        }
    } catch {
    }

    return $false
}

function Get-DriverPackUsbCacheTarget {
    param(
        [Parameter()]
        [Int64]$MinimumFreeBytes = 10GB
    )

    $cacheRoots = @(
        Get-OSDCloudCache -ErrorAction SilentlyContinue |
            Where-Object { $_.Type -eq 'Cache' -and -not [string]::IsNullOrWhiteSpace([string]$_.DriveRoot) }
    )

    if (-not $cacheRoots) {
        return $null
    }

    $eligibleTargets = foreach ($cacheRoot in $cacheRoots) {
        $driveRoot = [string]$cacheRoot.DriveRoot
        if (-not (Test-IsUsbDriveRoot -DriveRoot $driveRoot)) {
            continue
        }

        $driveLetter = $driveRoot.TrimEnd('\\').TrimEnd(':')
        $drive = Get-PSDrive -Name $driveLetter -PSProvider FileSystem -ErrorAction SilentlyContinue
        if (-not $drive) {
            continue
        }

        $freeBytes = [Int64]$drive.Free
        if ($freeBytes -gt $MinimumFreeBytes) {
            [PSCustomObject]@{
                DriveRoot   = $driveRoot
                CachePath   = [string]$cacheRoot.FullName
                FreeBytes   = $freeBytes
                VolumeLabel = [string]$cacheRoot.VolumeLabel
            }
        }
    }

    return $eligibleTargets | Sort-Object -Property FreeBytes -Descending | Select-Object -First 1
}

function Convert-ToSafePathSegment {
    param(
        [Parameter()]
        [string]$Value,

        [Parameter()]
        [string]$DefaultValue = 'Unknown'
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $DefaultValue
    }

    $safeValue = $Value
    foreach ($invalidChar in [System.IO.Path]::GetInvalidFileNameChars()) {
        $safeValue = $safeValue.Replace([string]$invalidChar, '_')
    }

    if ([string]::IsNullOrWhiteSpace($safeValue)) {
        return $DefaultValue
    }

    return $safeValue
}

function Convert-ToSingleQuotedPowerShellLiteral {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    return "'" + $Value.Replace("'", "''") + "'"
}

function Get-DriverPackFileName {
    param(
        [Parameter()]
        $DriverPackObject
    )

    if (-not $DriverPackObject) {
        return $null
    }

    $fileName = [string]$DriverPackObject.FileName
    if (-not [string]::IsNullOrWhiteSpace($fileName)) {
        return [System.IO.Path]::GetFileName($fileName)
    }

    $url = [string]$DriverPackObject.Url
    if ([string]::IsNullOrWhiteSpace($url)) {
        return $null
    }

    try {
        return [System.IO.Path]::GetFileName(([System.Uri]$url).AbsolutePath)
    } catch {
        return [System.IO.Path]::GetFileName($url)
    }
}

function Get-CloudOperatingSystemFileName {
    param(
        [Parameter()]
        $OperatingSystemObject
    )

    if (-not $OperatingSystemObject) {
        return $null
    }

    $fileName = [string]$OperatingSystemObject.FileName
    if (-not [string]::IsNullOrWhiteSpace($fileName)) {
        return [System.IO.Path]::GetFileName($fileName)
    }

    $filePath = [string]$OperatingSystemObject.FilePath
    if ([string]::IsNullOrWhiteSpace($filePath)) {
        return $null
    }

    try {
        return [System.IO.Path]::GetFileName(([System.Uri]$filePath).AbsolutePath)
    } catch {
        return [System.IO.Path]::GetFileName($filePath)
    }
}

function Get-CloudOperatingSystemCacheItems {
    return @(
        Get-OSDCloudCache -Type ESD, WIM -ErrorAction SilentlyContinue |
            Where-Object { $_.Type -in @('ESD', 'WIM') -and -not [string]::IsNullOrWhiteSpace([string]$_.FullName) }
    )
}

function Get-CloudOperatingSystemCacheFile {
    param(
        [Parameter()]
        $OperatingSystemObject,

        [Parameter()]
        [System.Object[]]$CacheItems
    )

    if (-not $OperatingSystemObject -or -not $CacheItems) {
        return $null
    }

    $candidateFileNames = @()

    $fileName = [string]$OperatingSystemObject.FileName
    if (-not [string]::IsNullOrWhiteSpace($fileName)) {
        $candidateFileNames += [System.IO.Path]::GetFileName($fileName)
    }

    $filePath = [string]$OperatingSystemObject.FilePath
    if (-not [string]::IsNullOrWhiteSpace($filePath)) {
        try {
            $candidateFileNames += [System.IO.Path]::GetFileName(([System.Uri]$filePath).AbsolutePath)
        } catch {
            $candidateFileNames += [System.IO.Path]::GetFileName($filePath)
        }
    }

    $candidateFileNames = @(
        $candidateFileNames |
            Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } |
            Sort-Object -Unique
    )

    if (-not $candidateFileNames) {
        return $null
    }

    return $CacheItems | Where-Object {
        $cacheFileName = [System.IO.Path]::GetFileName([string]$_.FullName)
        $candidateFileNames -icontains $cacheFileName
    } | Select-Object -First 1
}

function Get-DriverFolderRelativePath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $relativePathMatch = [System.Text.RegularExpressions.Regex]::Match($Path, '(?i)(OSDCloud\\Drivers(?:\\.*)?)$')
    if ($relativePathMatch.Success) {
        return $relativePathMatch.Groups[1].Value
    }

    return $null
}

function Get-DriveVolumeMetadata {
    param(
        [Parameter(Mandatory)]
        [string]$DriveRoot
    )

    $volume = $null
    if ($DriveRoot -match '^[A-Z]:\\$') {
        try {
            $volume = Get-Volume -DriveLetter $DriveRoot.Substring(0, 1) -ErrorAction Stop
        } catch {
            $volume = $null
        }
    }

    return [PSCustomObject]@{
        DriveRoot      = $DriveRoot
        VolumeLabel    = if ($volume) { [string]$volume.FileSystemLabel } else { $null }
        VolumeUniqueId = if ($volume) { [string]$volume.UniqueId } else { $null }
    }
}

function Get-DriverFolderItem {
    $driverFolders = Get-OSDCloudCache -Type Drivers -ErrorAction SilentlyContinue |
        Where-Object { $_.Type -eq 'Drivers' -and -not [string]::IsNullOrWhiteSpace([string]$_.FullName) } |
        ForEach-Object {
            $folderPath = [string]$_.FullName
            $folderName = [System.IO.Path]::GetFileName($folderPath)
            $isAutoDefaultMatch = @('Auto', 'Default') -contains $folderName
            $isManufacturerMatch = (-not [string]::IsNullOrWhiteSpace($deviceOSDManufacturer)) -and ($folderName -ieq [string]$deviceOSDManufacturer)
            $isModelMatch = (-not [string]::IsNullOrWhiteSpace($deviceOSDModel)) -and ($folderName -like "*$deviceOSDModel*")
            $isProductMatch = (-not [string]::IsNullOrWhiteSpace($deviceOSDProduct)) -and ($folderName -like "*$deviceOSDProduct*")

            [PSCustomObject]@{
                Name           = $folderPath
                Path           = $folderPath
                RelativePath   = Get-DriverFolderRelativePath -Path $folderPath
                DriveRoot      = [string]$_.DriveRoot
                VolumeLabel    = [string]$_.VolumeLabel
                VolumeUniqueId = [string]$_.VolumeUniqueId
                IsSelected     = ($isAutoDefaultMatch -or $isManufacturerMatch -or $isModelMatch -or $isProductMatch)
            }
        }

    return @($driverFolders | Sort-Object -Property Path -Unique)
}

$LocalIsoCard             = $window.FindName("LocalIsoCard")
$UseLocalIsoToggle       = $window.FindName("UseLocalIsoToggle")
$LocalIsoCombo           = $window.FindName("LocalIsoCombo")
$CloudOperatingSystemCard = $window.FindName("CloudOperatingSystemCard")
$LocalIsoFiles           = @(Get-LocalIsoFile)
$DriverPackCacheItems    = @(Get-DriverPackCacheItems)

if ($LocalIsoFiles.Count -gt 0) {
    $LocalIsoCard.Visibility = [System.Windows.Visibility]::Visible
    $LocalIsoCombo.ItemsSource = $LocalIsoFiles
    $LocalIsoCombo.DisplayMemberPath = 'FullName'
    $LocalIsoCombo.SelectedIndex = 0
}

$DriverFolderPanel    = $window.FindName("DriverFolderPanel")
$DriverFolderExpander = $window.FindName("DriverFolderExpander")
$DriverFolderGridBorder = $window.FindName("DriverFolderGridBorder")
$DriverFolderGrid     = $window.FindName("DriverFolderGrid")
$DriverFolderPathText = $window.FindName("DriverFolderPathText")
$DriverFolderEmptyHelpText = $window.FindName("DriverFolderEmptyHelpText")
$DriverFolderItems    = @(Get-DriverFolderItem)

if ($DriverFolderItems.Count -gt 0) {
    $selectedDriverFolderPaths = @()
    $selectedDriverFolderSelections = @()
    if ($global:OSDCloudDeploy.DriverFolderSelections) {
        $selectedDriverFolderSelections = @($global:OSDCloudDeploy.DriverFolderSelections)
    }
    if ($global:OSDCloudDeploy.DriverFolderPaths) {
        $selectedDriverFolderPaths = @($global:OSDCloudDeploy.DriverFolderPaths)
    } elseif ($global:OSDCloudDeploy.DriverFolderPath) {
        $selectedDriverFolderPaths = @([string]$global:OSDCloudDeploy.DriverFolderPath)
    }

    foreach ($driverFolderItem in $DriverFolderItems) {
        $selectionMatch = $selectedDriverFolderSelections | Where-Object {
            ((-not [string]::IsNullOrWhiteSpace([string]$_.Path)) -and ([string]$_.Path -eq [string]$driverFolderItem.Path)) -or
            ((-not [string]::IsNullOrWhiteSpace([string]$_.RelativePath)) -and ([string]$_.RelativePath -eq [string]$driverFolderItem.RelativePath) -and ([string]$_.VolumeLabel -eq [string]$driverFolderItem.VolumeLabel)) -or
            ((-not [string]::IsNullOrWhiteSpace([string]$_.RelativePath)) -and ([string]$_.RelativePath -eq [string]$driverFolderItem.RelativePath) -and ([string]$_.VolumeUniqueId -eq [string]$driverFolderItem.VolumeUniqueId))
        } | Select-Object -First 1

        if ($selectionMatch -or ($selectedDriverFolderPaths -contains [string]$driverFolderItem.Path)) {
            $driverFolderItem.IsSelected = $true
        }
    }

    $DriverFolderGrid.ItemsSource = $DriverFolderItems
    $DriverFolderPanel.IsEnabled = $true
    $DriverFolderGrid.IsEnabled = $true
    if ($DriverFolderGridBorder) {
        $DriverFolderGridBorder.Visibility = [System.Windows.Visibility]::Visible
    }
    if ($DriverFolderExpander) {
        $DriverFolderExpander.IsExpanded = $true
    }
    if ($DriverFolderEmptyHelpText) {
        $DriverFolderEmptyHelpText.Visibility = [System.Windows.Visibility]::Collapsed
    }
} else {
    $DriverFolderGrid.ItemsSource = @()
    # Keep panel enabled so the collapsed card can still be expanded for guidance text.
    $DriverFolderPanel.IsEnabled = $true
    $DriverFolderGrid.IsEnabled = $false
    if ($DriverFolderGridBorder) {
        $DriverFolderGridBorder.Visibility = [System.Windows.Visibility]::Collapsed
    }
    if ($DriverFolderExpander) {
        $DriverFolderExpander.IsExpanded = $false
    }
    if ($DriverFolderEmptyHelpText) {
        $DriverFolderEmptyHelpText.Visibility = [System.Windows.Visibility]::Visible
    }
    $global:OSDCloudDeploy.DriverFolderName = $null
    $global:OSDCloudDeploy.DriverFolderPath = $null
    $global:OSDCloudDeploy.DriverFolderNames = @()
    $global:OSDCloudDeploy.DriverFolderPaths = @()
    $global:OSDCloudDeploy.DriverFolderSelections = @()
}
#================================================
# Operating System Values
if ($global:OSDCloudDeploy.OperatingSystemValues) {
    $OperatingSystemValues = $global:OSDCloudDeploy.OperatingSystemValues
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] OperatingSystemValues = $OperatingSystemValues"
} else {
    $OperatingSystemValues = $global:DeployOSDCloudOperatingSystems.OperatingSystem | Sort-Object -Unique | Sort-Object -Descending
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] Catalog OperatingSystemValues = $OperatingSystemValues"
}
$OperatingSystemCombo            = $window.FindName("OperatingSystemCombo")
$OperatingSystemCombo.ItemsSource = $OperatingSystemValues
#================================================
# OperatingSystem Default
if ($global:OSDCloudDeploy.OperatingSystem) {
    $OperatingSystemDefault = $global:OSDCloudDeploy.OperatingSystem
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] OperatingSystem = $OperatingSystemDefault"
}
if ($OperatingSystemDefault -and ($OperatingSystemValues -contains $OperatingSystemDefault)) {
    $OperatingSystemCombo.SelectedItem = $OperatingSystemDefault
} elseif ($OperatingSystemValues) {
    $OperatingSystemCombo.SelectedIndex = 0
} else {
    $OperatingSystemCombo.SelectedIndex = -1
}
#================================================
# OS Edition Values
if ($global:OSDCloudDeploy.OSEditionValues.Edition) {
    $OSEditionValues = $global:OSDCloudDeploy.OSEditionValues.Edition
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] OSEditionValues = $OSEditionValues"
} else {
    $OSEditionValues = @()
}
$OSEditionCombo            = $window.FindName("OSEditionCombo")
$OSEditionCombo.ItemsSource = $OSEditionValues
#================================================
# OS Edition Default
if ($global:OSDCloudDeploy.OSEdition) {
    $OSEditionDefault = $global:OSDCloudDeploy.OSEdition
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] OSEdition = $OSEditionDefault"
}
if ($OSEditionDefault) {
    $OSEditionCombo.SelectedItem = $OSEditionDefault
} elseif ($OperatingSystemValues) {
    $OSEditionCombo.SelectedIndex = 0
} else {
    $OSEditionCombo.SelectedIndex = -1
}
#================================================
# OS Activation Values
if ($global:OSDCloudDeploy.OSActivationValues) {
    $OSActivationValues = $global:OSDCloudDeploy.OSActivationValues
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] OSActivationValues = $OSActivationValues"
} else {
    $OSActivationValues = @()
}
$OSActivationCombo            = $window.FindName("OSActivationCombo")
$OSActivationCombo.ItemsSource = $OSActivationValues
#================================================
# OS Activation Default
if ($global:OSDCloudDeploy.OSActivation) {
    $OSActivationDefault = $global:OSDCloudDeploy.OSActivation
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] OSActivation = $OSActivationDefault"
}
if ($OSActivationDefault -and ($OSActivationValues -contains $OSActivationDefault)) {
    $OSActivationCombo.SelectedItem = $OSActivationDefault
} elseif ($OSActivationValues) {
    $OSActivationCombo.SelectedIndex = 0
} else {
    $OSActivationCombo.SelectedIndex = -1
}
#================================================
# OS Language Code Values
if ($global:OSDCloudDeploy.OSLanguageCodeValues) {
    $OSLanguageCodeValues = $global:OSDCloudDeploy.OSLanguageCodeValues
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] OSLanguageCodeValues = $OSLanguageCodeValues"
} else {
    $OSLanguageCodeValues = $global:DeployOSDCloudOperatingSystems.OSLanguageCode | Sort-Object -Unique | Sort-Object -Descending
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] Catalog OSLanguageCodeValues = $OSLanguageCodeValues"
}
$OSLanguageCodeCombo            = $window.FindName("OSLanguageCodeCombo")
$OSLanguageCodeCombo.ItemsSource = $OSLanguageCodeValues
#================================================
# OS Language Code Default
if ($global:OSDCloudDeploy.OSLanguageCode) {
    $OSLanguageCodeDefault = $global:OSDCloudDeploy.OSLanguageCode
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] OSLanguage = $OSLanguageCodeDefault"
}
if ($OSLanguageCodeDefault -and ($OSLanguageCodeValues -contains $OSLanguageCodeDefault)) {
    $OSLanguageCodeCombo.SelectedItem = $OSLanguageCodeDefault
} elseif ($OSLanguageCodeValues) {
    $OSLanguageCodeCombo.SelectedIndex = 0
} else {
    $OSLanguageCodeCombo.SelectedIndex = -1
}
#================================================
# Driver Pack Combo
$DriverPackCatalog = @('None', 'Microsoft Update Catalog')
if ($global:OSDCloudDeploy.DriverPackValues) {
    $DriverPackCatalog += $global:OSDCloudDeploy.DriverPackValues | ForEach-Object { $_.Name }
}
$DriverPackCombo            = $window.FindName("DriverPackCombo")
$DriverPackCombo.ItemsSource = $DriverPackCatalog
if ($global:OSDCloudDeploy.DriverPackName) {
    $DriverPackCombo.SelectedValue = $global:OSDCloudDeploy.DriverPackName
} else {
    $DriverPackCombo.SelectedIndex = 0
}
#================================================
# Device Info Text Blocks
$deviceBiosReleaseDateText       = $window.FindName("deviceBiosReleaseDateText")
$deviceBiosReleaseDateText.Text  = $deviceBiosReleaseDate
$deviceBiosVersionText           = $window.FindName("deviceBiosVersionText")
$deviceBiosVersionText.Text      = $deviceBiosVersion
$deviceOSDManufacturerText       = $window.FindName("deviceOSDManufacturerText")
$deviceOSDManufacturerText.Text  = $deviceOSDManufacturer
$deviceOSDModelText              = $window.FindName("deviceOSDModelText")
$deviceOSDModelText.Text         = $deviceOSDModel
$deviceOSDProductText            = $window.FindName("deviceOSDProductText")
$deviceOSDProductText.Text       = $deviceOSDProduct
$deviceComputerSystemSKUText     = $window.FindName("deviceComputerSystemSKUText")
$deviceComputerSystemSKUText.Text = $deviceComputerSystemSKU

function Set-ClipboardText {
    param([string]$Text)
    $maxRetries = 5
    for ($i = 0; $i -lt $maxRetries; $i++) {
        try {
            [System.Windows.Clipboard]::SetText($Text)
            return
        } catch {
            if ($i -lt ($maxRetries - 1)) {
                Start-Sleep -Milliseconds 100
            } else {
                Write-Warning "Failed to copy to clipboard: $_"
            }
        }
    }
}

$deviceSerialNumberText      = $window.FindName("deviceSerialNumberText")
$deviceSerialNumberText.Text = $deviceSerialNumber
$deviceSerialNumberText.Add_MouseLeftButtonUp({
    $serialNumberValue = [string]$deviceSerialNumberText.Text
    if ([string]::IsNullOrWhiteSpace($serialNumberValue)) { return }
    Set-ClipboardText -Text $serialNumberValue
})

$deviceIsAutopilotSpecText       = $window.FindName("deviceIsAutopilotSpecText")
$deviceIsAutopilotSpecText.Text  = $deviceIsAutopilotSpec
$deviceIsTpmSpecText             = $window.FindName("deviceIsTpmSpecText")
$deviceIsTpmSpecText.Text        = $deviceIsTpmSpec

$deviceUUIDText      = $window.FindName("deviceUUIDText")
$deviceUUIDText.Text = $deviceUUID
$deviceUUIDText.Add_MouseLeftButtonUp({
    $uuidValue = [string]$deviceUUIDText.Text
    if ([string]::IsNullOrWhiteSpace($uuidValue)) { return }
    Set-ClipboardText -Text $uuidValue
})

$deviceHardwareHashLabelText = $window.FindName("deviceHardwareHashLabelText")
$deviceHardwareHashText      = $window.FindName("deviceHardwareHashText")
if (-not [string]::IsNullOrWhiteSpace([string]$deviceHardwareHash)) {
    $deviceHardwareHashLabelText.Visibility = [System.Windows.Visibility]::Visible
    $deviceHardwareHashText.Text            = 'Copy to Clipboard'
    $deviceHardwareHashText.Visibility      = [System.Windows.Visibility]::Visible
    $deviceHardwareHashText.Add_MouseLeftButtonUp({
        Set-ClipboardText -Text ([string]$deviceHardwareHash)
    })
}

$OSDCloudDeviceGrid = $window.FindName('OSDCloudDeviceGrid')

function Convert-OSDCloudDeviceValueToString {
    param($Value)

    if ($null -eq $Value) {
        return ''
    }

    if ($Value -is [string]) {
        return $Value
    }

    if ($Value -is [System.Collections.IDictionary]) {
        return (($Value.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }) -join '; ')
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        return (($Value | ForEach-Object { [string]$_ }) -join ', ')
    }

    return [string]$Value
}

function Get-OSDCloudDeviceItems {
    $deviceObject = $global:OSDCloudDevice
    if (-not $deviceObject) {
        return @()
    }

    if ($deviceObject -is [System.Collections.IDictionary]) {
        return @(
            $deviceObject.GetEnumerator() |
                Sort-Object -Property Key |
                ForEach-Object {
                    [PSCustomObject]@{
                        Key   = [string]$_.Key
                        Value = Convert-OSDCloudDeviceValueToString -Value $_.Value
                    }
                }
        )
    }

    return @(
        $deviceObject.PSObject.Properties |
            Where-Object {
                $_.MemberType -in @('NoteProperty', 'Property') -and
                $_.IsGettable -and
                $_.Name -notlike 'PS*'
            } |
            Sort-Object -Property Name |
            ForEach-Object {
                [PSCustomObject]@{
                    Key   = [string]$_.Name
                    Value = Convert-OSDCloudDeviceValueToString -Value $_.Value
                }
            }
    )
}

if ($OSDCloudDeviceGrid) {
    $OSDCloudDeviceGrid.ItemsSource = Get-OSDCloudDeviceItems
}
#================================================
# Summary / Selected detail text blocks
$SelectedOSLanguageText  = $window.FindName("SelectedOSLanguageText")
$SelectedIdText          = $window.FindName("SelectedIdText")
$SelectedFileNameText    = $window.FindName("SelectedFileNameText")
$CloudOperatingSystemDownloadButton = $window.FindName("CloudOperatingSystemDownloadButton")
$DriverPackUrlText       = $window.FindName("DriverPackUrlText")
$DriverPackCacheLabelText = $window.FindName("DriverPackCacheLabelText")
$DriverPackCachePathText = $window.FindName("DriverPackCachePathText")
$DriverPackDownloadButton = $window.FindName("DriverPackDownloadButton")
$DriverPackUrlText.Text  = [string]$global:OSDCloudDeploy.DriverPackObject.Url
if ($global:OSDCloudDeploy.DriverFolderPaths.Count -gt 0) {
    $DriverFolderPathText.Text = ($global:OSDCloudDeploy.DriverFolderPaths -join '; ')
} else {
    $DriverFolderPathText.Text = [string]$global:OSDCloudDeploy.DriverFolderPath
}
#================================================
# Start Button
$StartButton            = $window.FindName("StartButton")
$StartButton.IsEnabled  = $false

function Get-ComboValue {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.ComboBox]$ComboBox
    )

    $value = $ComboBox.SelectedItem
    if ($null -eq $value) { return $null }
    $text = [string]$value
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    return $text
}

function Set-StartButtonState {
    $useLocalIso = $UseLocalIsoToggle -and $UseLocalIsoToggle.IsChecked -eq $true
    if ($useLocalIso) {
        $StartButton.IsEnabled = ($null -ne $LocalIsoCombo.SelectedItem)
    } else {
        $StartButton.IsEnabled = ($null -ne $global:OSDCloudDeploy.OperatingSystemObject)
    }
}

function Update-OperatingSystemSourceVisibility {
    $useLocalIso = $UseLocalIsoToggle -and $UseLocalIsoToggle.IsChecked -eq $true

    if ($useLocalIso) {
        $LocalIsoCombo.Visibility = [System.Windows.Visibility]::Visible
        $CloudOperatingSystemCard.Visibility = [System.Windows.Visibility]::Collapsed
    } else {
        $LocalIsoCombo.Visibility = [System.Windows.Visibility]::Collapsed
        $CloudOperatingSystemCard.Visibility = [System.Windows.Visibility]::Visible
    }

    Set-StartButtonState
}

function Update-SelectedDetails {
    param(
        [Parameter()]
        $Item
    )

    if (-not $Item) {
        $SelectedIdText.Text         = 'No matching catalog entry.'
        $SelectedOSLanguageText.Text = '-'
        $SelectedFileNameText.Text   = '-'
        return
    }

    $SelectedIdText.Text = [string]$Item.Id
    $SelectedOSLanguageText.Text = if ($Item.OSLanguage) {
        [string]$Item.OSLanguage
    } elseif ($Item.OSLanguageCode) {
        [string]$Item.OSLanguageCode
    } else {
        '-'
    }
    $SelectedFileNameText.Text = [string]$Item.FileName
}

function Update-CloudOperatingSystemDownloadState {
    if (-not $CloudOperatingSystemDownloadButton) {
        return
    }

    $useLocalIso = $UseLocalIsoToggle -and $UseLocalIsoToggle.IsChecked -eq $true
    $operatingSystemObject = $global:OSDCloudDeploy.OperatingSystemObject
    $operatingSystemUrl = if ($operatingSystemObject) { [string]$operatingSystemObject.FilePath } else { $null }
    $operatingSystemFileName = Get-CloudOperatingSystemFileName -OperatingSystemObject $operatingSystemObject
    $cloudCacheItems = @(Get-CloudOperatingSystemCacheItems)
    $matchedCloudCacheFile = Get-CloudOperatingSystemCacheFile -OperatingSystemObject $operatingSystemObject -CacheItems $cloudCacheItems
    $script:CloudOperatingSystemUsbTarget = Get-DriverPackUsbCacheTarget

    $hasDownloadableCloudOperatingSystem = -not $useLocalIso -and
        ($null -ne $operatingSystemObject) -and
        -not [string]::IsNullOrWhiteSpace($operatingSystemUrl) -and
        -not [string]::IsNullOrWhiteSpace($operatingSystemFileName)

    if ($hasDownloadableCloudOperatingSystem -and -not $matchedCloudCacheFile -and $script:CloudOperatingSystemUsbTarget) {
        $CloudOperatingSystemDownloadButton.Visibility = [System.Windows.Visibility]::Visible
        $targetDescription = [string]$script:CloudOperatingSystemUsbTarget.DriveRoot
        if (-not [string]::IsNullOrWhiteSpace([string]$script:CloudOperatingSystemUsbTarget.VolumeLabel)) {
            $targetDescription = "$targetDescription ($([string]$script:CloudOperatingSystemUsbTarget.VolumeLabel))"
        }
        $CloudOperatingSystemDownloadButton.ToolTip = "Download selected Cloud Operating System to $targetDescription"
    } else {
        $CloudOperatingSystemDownloadButton.Visibility = [System.Windows.Visibility]::Collapsed
        $CloudOperatingSystemDownloadButton.ToolTip = $null
    }
}

function Update-OsResults {
    $updateOperatingSystem = Get-ComboValue -ComboBox $OperatingSystemCombo
    $updateOSEdition       = Get-ComboValue -ComboBox $OSEditionCombo
    $updateOSActivation    = Get-ComboValue -ComboBox $OSActivationCombo
    $updateOSLanguageCode  = Get-ComboValue -ComboBox $OSLanguageCodeCombo

    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] updateOperatingSystem = $updateOperatingSystem"
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] updateOSEdition = $updateOSEdition"
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] updateOSActivation = $updateOSActivation"
    Write-Verbose "[$(Get-Date -format s)] [MainWindow.ps1] updateOSLanguageCode = $updateOSLanguageCode"

    $global:OSDCloudDeploy.OperatingSystemObject = $global:DeployOSDCloudOperatingSystems | `
        Where-Object { $_.OperatingSystem -match $updateOperatingSystem } | `
        Where-Object { $_.OSActivation -eq $updateOSActivation } | `
        Where-Object { $_.OSLanguageCode -eq $updateOSLanguageCode } | Select-Object -First 1

    if (-not $global:OSDCloudDeploy.OperatingSystemObject) {
        throw "No Operating System found for OperatingSystem: $updateOperatingSystem, OSActivation: $updateOSActivation, OSLanguageCode: $updateOSLanguageCode. Please check your OSDCloud OperatingSystems."
    }

    $script:SelectedImage = $global:OSDCloudDeploy.OperatingSystemObject

    if ($updateOSEdition -match 'Home') {
        $OSActivationCombo.SelectedValue = 'Retail'
        $OSActivationCombo.IsEnabled     = $false
    }
    if ($updateOSEdition -match 'Education') {
        $OSActivationCombo.IsEnabled = $true
    }
    if ($updateOSEdition -match 'Enterprise') {
        $OSActivationCombo.SelectedValue = 'Volume'
        $OSActivationCombo.IsEnabled     = $false
    }
    if ($updateOSEdition -match 'Pro') {
        $OSActivationCombo.IsEnabled = $true
    }

    Update-SelectedDetails -Item $script:SelectedImage
    Update-CloudOperatingSystemDownloadState
    Set-StartButtonState
}

function Update-DriverPackResults {
    Update-CloudOperatingSystemDownloadState
    $selectedDriverPackName                      = Get-ComboValue -ComboBox $DriverPackCombo
    $global:OSDCloudDeploy.DriverPackName        = $selectedDriverPackName
    $global:OSDCloudDeploy.DriverPackObject      = $global:OSDCloudDeploy.DriverPackValues | Where-Object { $_.Name -eq $selectedDriverPackName } | Select-Object -First 1
    $DriverPackUrlText.Text                      = [string]$global:OSDCloudDeploy.DriverPackObject.Url
    $DriverPackCacheItems                        = @(Get-DriverPackCacheItems)

    $matchedCacheFile = Get-DriverPackCacheFile -DriverPackObject $global:OSDCloudDeploy.DriverPackObject -CacheItems $DriverPackCacheItems
    $script:DriverPackUsbTarget = Get-DriverPackUsbCacheTarget

    if ($matchedCacheFile) {
        $DriverPackCachePathText.Text = [string]$matchedCacheFile.FullName
        $DriverPackCachePathText.Visibility = [System.Windows.Visibility]::Visible
        $DriverPackCacheLabelText.Visibility = [System.Windows.Visibility]::Visible
    } else {
        $DriverPackCachePathText.Text = ''
        $DriverPackCachePathText.Visibility = [System.Windows.Visibility]::Collapsed
        $DriverPackCacheLabelText.Visibility = [System.Windows.Visibility]::Collapsed
    }

    if ($DriverPackDownloadButton) {
        $hasDownloadableDriverPack = ($null -ne $global:OSDCloudDeploy.DriverPackObject) -and
            -not [string]::IsNullOrWhiteSpace([string]$global:OSDCloudDeploy.DriverPackObject.Url) -and
            -not [string]::IsNullOrWhiteSpace((Get-DriverPackFileName -DriverPackObject $global:OSDCloudDeploy.DriverPackObject)
            )

        if ($hasDownloadableDriverPack -and -not $matchedCacheFile -and $script:DriverPackUsbTarget) {
            $DriverPackDownloadButton.Visibility = [System.Windows.Visibility]::Visible
            $targetDescription = [string]$script:DriverPackUsbTarget.DriveRoot
            if (-not [string]::IsNullOrWhiteSpace([string]$script:DriverPackUsbTarget.VolumeLabel)) {
                $targetDescription = "$targetDescription ($([string]$script:DriverPackUsbTarget.VolumeLabel))"
            }
            $DriverPackDownloadButton.ToolTip = "Download selected Driver Pack to $targetDescription"
        } else {
            $DriverPackDownloadButton.Visibility = [System.Windows.Visibility]::Collapsed
            $DriverPackDownloadButton.ToolTip = $null
        }
    }
}

function Update-DriverFolderResults {
    $selectedDriverFolderItems = @($DriverFolderGrid.ItemsSource | Where-Object {
            $_.IsSelected -eq $true -and -not [string]::IsNullOrWhiteSpace([string]$_.Path)
        })

    if ($selectedDriverFolderItems.Count -gt 0) {
        $global:OSDCloudDeploy.DriverFolderNames = @($selectedDriverFolderItems | ForEach-Object { [string]$_.Name })
        $global:OSDCloudDeploy.DriverFolderPaths = @($selectedDriverFolderItems | ForEach-Object { [string]$_.Path })
        $global:OSDCloudDeploy.DriverFolderSelections = @($selectedDriverFolderItems | ForEach-Object {
                [PSCustomObject]@{
                    Path           = [string]$_.Path
                    RelativePath   = [string]$_.RelativePath
                    DriveRoot      = [string]$_.DriveRoot
                    VolumeLabel    = [string]$_.VolumeLabel
                    VolumeUniqueId = [string]$_.VolumeUniqueId
                    Name           = [string]$_.Name
                }
            })

        # Backward compatibility for existing single-folder consumers.
        $global:OSDCloudDeploy.DriverFolderName = $global:OSDCloudDeploy.DriverFolderNames | Select-Object -First 1
        $global:OSDCloudDeploy.DriverFolderPath = $global:OSDCloudDeploy.DriverFolderPaths | Select-Object -First 1
    } else {
        $global:OSDCloudDeploy.DriverFolderName = $null
        $global:OSDCloudDeploy.DriverFolderPath = $null
        $global:OSDCloudDeploy.DriverFolderNames = @()
        $global:OSDCloudDeploy.DriverFolderPaths = @()
        $global:OSDCloudDeploy.DriverFolderSelections = @()
    }

    if ($global:OSDCloudDeploy.DriverFolderPaths.Count -gt 0) {
        $DriverFolderPathText.Text = ($global:OSDCloudDeploy.DriverFolderPaths -join '; ')
    } else {
        $DriverFolderPathText.Text = ''
    }
}

function Request-DriverFolderResultsRefresh {
    if ($window -and $window.Dispatcher) {
        $window.Dispatcher.InvokeAsync({
                $DriverFolderGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true) | Out-Null
                $DriverFolderGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true) | Out-Null
                Update-DriverFolderResults
            },
            [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
    } else {
        Update-DriverFolderResults
    }
}

$DriverPackCombo.Add_SelectionChanged({ Update-DriverPackResults })
$DriverFolderGrid.Add_CurrentCellChanged({ Request-DriverFolderResultsRefresh })
$DriverFolderGrid.Add_CellEditEnding({ Request-DriverFolderResultsRefresh })
$DriverFolderGrid.Add_PreviewMouseLeftButtonUp({ Request-DriverFolderResultsRefresh })
$DriverFolderGrid.Add_PreviewKeyUp({
        param($eventSource, $keyEvent)

        if ($keyEvent.Key -eq [System.Windows.Input.Key]::Space -or $keyEvent.Key -eq [System.Windows.Input.Key]::Enter) {
            Request-DriverFolderResultsRefresh
        }
    })
$UseLocalIsoToggle.Add_Checked({ Update-OperatingSystemSourceVisibility })
$UseLocalIsoToggle.Add_Unchecked({ Update-OperatingSystemSourceVisibility })
$LocalIsoCombo.Add_SelectionChanged({ Set-StartButtonState })
$OperatingSystemCombo.Add_SelectionChanged({ Update-OsResults })
$OSActivationCombo.Add_SelectionChanged({ Update-OsResults })
$OSEditionCombo.Add_SelectionChanged({ Update-OsResults })
$OSLanguageCodeCombo.Add_SelectionChanged({ Update-OsResults })
$script:SelectionConfirmed = $false

if ($DriverPackDownloadButton) {
    $DriverPackDownloadButton.Add_Click({
            $driverPackObject = $global:OSDCloudDeploy.DriverPackObject
            if (-not $driverPackObject) {
                [System.Windows.MessageBox]::Show('Select a Driver Pack before downloading.', 'Driver Pack Download', 'OK', 'Warning') | Out-Null
                return
            }

            $driverPackUrl = [string]$driverPackObject.Url
            $driverPackFileName = Get-DriverPackFileName -DriverPackObject $driverPackObject
            if ([string]::IsNullOrWhiteSpace($driverPackUrl) -or [string]::IsNullOrWhiteSpace($driverPackFileName)) {
                [System.Windows.MessageBox]::Show('The selected Driver Pack does not provide a downloadable URL or filename.', 'Driver Pack Download', 'OK', 'Warning') | Out-Null
                return
            }

            $usbTarget = Get-DriverPackUsbCacheTarget
            if (-not $usbTarget) {
                [System.Windows.MessageBox]::Show('No USB OSDCloud cache target with more than 10 GB free space is available.', 'Driver Pack Download', 'OK', 'Warning') | Out-Null
                Update-DriverPackResults
                return
            }

            $manufacturerFolderName = Convert-ToSafePathSegment -Value ([string]$deviceOSDManufacturer)
            if ([string]::IsNullOrWhiteSpace($manufacturerFolderName)) {
                $manufacturerFolderName = Convert-ToSafePathSegment -Value ([string]$driverPackObject.Manufacturer)
            }

            $destinationDirectory = Join-Path -Path ([string]$usbTarget.DriveRoot) -ChildPath ("OSDCloud\\DriverPacks\\$manufacturerFolderName")
            $destinationPath = Join-Path -Path $destinationDirectory -ChildPath $driverPackFileName

            $cacheMatch = Get-DriverPackCacheFile -DriverPackObject $driverPackObject -CacheItems (Get-DriverPackCacheItems)
            if ($cacheMatch) {
                Update-DriverPackResults
                [System.Windows.MessageBox]::Show("Driver Pack is already cached at $([string]$cacheMatch.FullName).", 'Driver Pack Download', 'OK', 'Information') | Out-Null
                return
            }

            $destinationDirectoryLiteral = Convert-ToSingleQuotedPowerShellLiteral -Value $destinationDirectory
            $destinationPathLiteral = Convert-ToSingleQuotedPowerShellLiteral -Value $destinationPath
            $driverPackUrlLiteral = Convert-ToSingleQuotedPowerShellLiteral -Value $driverPackUrl

            $downloadCommand = "`$ProgressPreference = 'SilentlyContinue'; New-Item -Path $destinationDirectoryLiteral -ItemType Directory -Force | Out-Null; & curl.exe --location --fail --output $destinationPathLiteral $driverPackUrlLiteral"

            try {
                Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $downloadCommand) -ErrorAction Stop
                # [System.Windows.MessageBox]::Show("Started download to $destinationPath", 'Driver Pack Download', 'OK', 'Information') | Out-Null
            } catch {
                [System.Windows.MessageBox]::Show("Failed to start Driver Pack download: $($_.Exception.Message)", 'Driver Pack Download', 'OK', 'Error') | Out-Null
            }

            Update-DriverPackResults
        })
}

if ($CloudOperatingSystemDownloadButton) {
    $CloudOperatingSystemDownloadButton.Add_Click({
            $useLocalIso = $UseLocalIsoToggle -and $UseLocalIsoToggle.IsChecked -eq $true
            if ($useLocalIso) {
                [System.Windows.MessageBox]::Show('Cloud Operating System download is unavailable while local ISO is selected.', 'Cloud Operating System Download', 'OK', 'Warning') | Out-Null
                Update-CloudOperatingSystemDownloadState
                return
            }

            $operatingSystemObject = $global:OSDCloudDeploy.OperatingSystemObject
            if (-not $operatingSystemObject) {
                [System.Windows.MessageBox]::Show('Select a Cloud Operating System before downloading.', 'Cloud Operating System Download', 'OK', 'Warning') | Out-Null
                return
            }

            $operatingSystemUrl = [string]$operatingSystemObject.FilePath
            $operatingSystemFileName = Get-CloudOperatingSystemFileName -OperatingSystemObject $operatingSystemObject
            if ([string]::IsNullOrWhiteSpace($operatingSystemUrl) -or [string]::IsNullOrWhiteSpace($operatingSystemFileName)) {
                [System.Windows.MessageBox]::Show('The selected Cloud Operating System does not provide a downloadable URL or filename.', 'Cloud Operating System Download', 'OK', 'Warning') | Out-Null
                return
            }

            $usbTarget = Get-DriverPackUsbCacheTarget
            if (-not $usbTarget) {
                [System.Windows.MessageBox]::Show('No USB OSDCloud cache target with more than 10 GB free space is available.', 'Cloud Operating System Download', 'OK', 'Warning') | Out-Null
                Update-CloudOperatingSystemDownloadState
                return
            }

            $destinationDirectory = Join-Path -Path ([string]$usbTarget.DriveRoot) -ChildPath 'OSDCloud\OS'
            $destinationPath = Join-Path -Path $destinationDirectory -ChildPath $operatingSystemFileName

            $cacheMatch = Get-CloudOperatingSystemCacheFile -OperatingSystemObject $operatingSystemObject -CacheItems (Get-CloudOperatingSystemCacheItems)
            if ($cacheMatch) {
                Update-CloudOperatingSystemDownloadState
                [System.Windows.MessageBox]::Show("Cloud Operating System is already cached at $([string]$cacheMatch.FullName).", 'Cloud Operating System Download', 'OK', 'Information') | Out-Null
                return
            }

            $destinationDirectoryLiteral = Convert-ToSingleQuotedPowerShellLiteral -Value $destinationDirectory
            $destinationPathLiteral = Convert-ToSingleQuotedPowerShellLiteral -Value $destinationPath
            $operatingSystemUrlLiteral = Convert-ToSingleQuotedPowerShellLiteral -Value $operatingSystemUrl

            $downloadCommand = "`$ProgressPreference = 'SilentlyContinue'; New-Item -Path $destinationDirectoryLiteral -ItemType Directory -Force | Out-Null; & curl.exe --location --fail --output $destinationPathLiteral $operatingSystemUrlLiteral"

            try {
                Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $downloadCommand) -ErrorAction Stop
            } catch {
                [System.Windows.MessageBox]::Show("Failed to start Cloud Operating System download: $($_.Exception.Message)", 'Cloud Operating System Download', 'OK', 'Error') | Out-Null
            }

            Update-CloudOperatingSystemDownloadState
        })
}

$StartButton.Add_Click({
    $TaskSequenceStepsGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true) | Out-Null
    $TaskSequenceStepsGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true) | Out-Null
    $DriverFolderGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true) | Out-Null
    $DriverFolderGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true) | Out-Null
    Update-DriverFolderResults
    Save-TaskSequenceSteps -TaskSequenceName $script:CurrentTaskSequenceName -Steps $TaskSequenceStepsGrid.ItemsSource
    $script:SelectionConfirmed = $true
    $window.DialogResult = $true
    $window.Close()
})

Update-OsResults
Update-OperatingSystemSourceVisibility
Update-CloudOperatingSystemDownloadState
Update-DriverPackResults
Update-DriverFolderResults

# Initialize task sequence summary if present
if ($SummaryTaskSequenceText) {
    $value = [string]$TaskSequenceCombo.SelectedItem
    $SummaryTaskSequenceText.Text = if (-not [string]::IsNullOrWhiteSpace($value)) { $value } else { 'Not selected' }
}

$null = $window.ShowDialog()

if ($script:SelectionConfirmed) {
    #================================================
    # Local Variables
    $OSDCloudWorkflowTaskName   = $TaskSequenceCombo.SelectedValue
    $OSDCloudWorkflowTaskObject = $global:OSDCloudDeploy.Flows | Where-Object { $_.Name -eq $OSDCloudWorkflowTaskName } | Select-Object -First 1
    $useLocalIso                = $UseLocalIsoToggle -and $UseLocalIsoToggle.IsChecked -eq $true

    if ($useLocalIso) {
        $LocalImageFileInfo  = $LocalIsoCombo.SelectedItem
        $LocalImageFilePath  = [string]$LocalImageFileInfo.FullName
        $LocalImageName      = $null
        $OSEditionId         = $null
        $OperatingSystemObject = [PSCustomObject]@{
            FileName         = $LocalImageFileInfo.Name
            FilePath         = $LocalImageFilePath
            OperatingSystem  = 'Local ISO'
            OSName           = 'Local ISO'
            OSActivation     = $null
            OSBuild          = $null
            OSBuildVersion   = $null
            OSLanguageCode   = $null
            OSVersion        = $null
        }
    } else {
        $OperatingSystemObject = $global:OSDCloudDeploy.OperatingSystemObject
        $OSEditionId           = $global:OSDCloudDeploy.OSEditionValues | Where-Object { $_.Edition -eq $OSEditionCombo.SelectedValue } | Select-Object -ExpandProperty EditionId
    }
    #================================================
    # Global Variables
    $global:OSDCloudDeploy.WorkflowTaskName    = $OSDCloudWorkflowTaskName
    $global:OSDCloudDeploy.WorkflowTaskObject  = $OSDCloudWorkflowTaskObject
    $global:OSDCloudDeploy.ImageFileName       = $OperatingSystemObject.FileName
    $global:OSDCloudDeploy.ImageFileUrl        = $OperatingSystemObject.FilePath
    $global:OSDCloudDeploy.OperatingSystemObject = $OperatingSystemObject
    $global:OSDCloudDeploy.OperatingSystem     = $OperatingSystemObject.OSName
    $global:OSDCloudDeploy.OSActivation        = $OperatingSystemObject.OSActivation
    $global:OSDCloudDeploy.OSBuild             = $OperatingSystemObject.OSBuild
    $global:OSDCloudDeploy.OSEdition           = if ($useLocalIso) { $null } else { Get-ComboValue -ComboBox $OSEditionCombo }
    $global:OSDCloudDeploy.OSEditionId         = $OSEditionId
    $global:OSDCloudDeploy.OSLanguageCode      = $OperatingSystemObject.OSLanguageCode
    $global:OSDCloudDeploy.OperatingSystem     = $OperatingSystemObject.OperatingSystem
    $global:OSDCloudDeploy.OSVersion           = $OperatingSystemObject.OSVersion
    $global:OSDCloudDeploy.TimeStart           = (Get-Date)
    $global:OSDCloudDeploy.LocalImageFileInfo  = $LocalImageFileInfo
    $global:OSDCloudDeploy.LocalImageFilePath  = $LocalImageFilePath
    $global:OSDCloudDeploy.LocalImageName      = $LocalImageName
    Update-DriverFolderResults

    $LogsPath = "$env:TEMP\osdcloud-logs"
    if (-not (Test-Path -Path $LogsPath)) {
        New-Item -Path $LogsPath -ItemType Directory -Force | Out-Null
    }
    $global:OSDCloudDeploy | ConvertTo-Json | Out-File -FilePath "$LogsPath\OSDCloudDeploy.json" -Encoding utf8 -Width 2000 -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
}
