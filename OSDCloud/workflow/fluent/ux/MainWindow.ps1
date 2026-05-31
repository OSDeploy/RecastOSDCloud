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
$DiskPanel       = $window.FindName('DiskPanel')
$IdentityPanel   = $window.FindName('IdentityPanel')
$DeploymentPanel = $window.FindName('DeploymentPanel')
$StepsPanel      = $window.FindName('StepsPanel')
$PrivacyPanel    = $window.FindName('PrivacyPanel')

$NavListBox.SelectedIndex = 0
$NavListBox.Add_SelectionChanged({
    $tag = if ($NavListBox.SelectedItem) { [string]$NavListBox.SelectedItem.Tag } else { 'Device' }
    $DevicePanel.Visibility     = if ($tag -eq 'Device')     { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    $DiskPanel.Visibility       = if ($tag -eq 'Disk')       { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    $IdentityPanel.Visibility   = if ($tag -eq 'Identity')   { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
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
    param($eventSource, $eventArgs)

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
    $localIsoFiles = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' } | ForEach-Object {
        $osPath = Join-Path -Path $_.Root -ChildPath 'OSDCloud\OS'
        if (Test-Path -LiteralPath $osPath) {
            Get-ChildItem -LiteralPath $osPath -Filter '*.iso' -File -ErrorAction SilentlyContinue
        }
    }

    return @($localIsoFiles | Sort-Object -Property FullName -Unique)
}

$LocalIsoCard             = $window.FindName("LocalIsoCard")
$UseLocalIsoToggle       = $window.FindName("UseLocalIsoToggle")
$LocalIsoCombo           = $window.FindName("LocalIsoCombo")
$CloudOperatingSystemCard = $window.FindName("CloudOperatingSystemCard")
$LocalIsoFiles           = @(Get-LocalIsoFile)

if ($LocalIsoFiles.Count -gt 0) {
    $LocalIsoCard.Visibility = [System.Windows.Visibility]::Visible
    $LocalIsoCombo.ItemsSource = $LocalIsoFiles
    $LocalIsoCombo.DisplayMemberPath = 'FullName'
    $LocalIsoCombo.SelectedIndex = 0
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
#================================================
# Summary / Selected detail text blocks
$SelectedOSLanguageText  = $window.FindName("SelectedOSLanguageText")
$SelectedIdText          = $window.FindName("SelectedIdText")
$SelectedFileNameText    = $window.FindName("SelectedFileNameText")
$DriverPackUrlText       = $window.FindName("DriverPackUrlText")
$DriverPackUrlText.Text  = [string]$global:OSDCloudDeploy.DriverPackObject.Url
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
    Set-StartButtonState
}

function Update-DriverPackResults {
    $selectedDriverPackName                      = Get-ComboValue -ComboBox $DriverPackCombo
    $global:OSDCloudDeploy.DriverPackName        = $selectedDriverPackName
    $global:OSDCloudDeploy.DriverPackObject      = $global:OSDCloudDeploy.DriverPackValues | Where-Object { $_.Name -eq $selectedDriverPackName }
    $DriverPackUrlText.Text                      = [string]$global:OSDCloudDeploy.DriverPackObject.Url
}

$DriverPackCombo.Add_SelectionChanged({ Update-DriverPackResults })
$UseLocalIsoToggle.Add_Checked({ Update-OperatingSystemSourceVisibility })
$UseLocalIsoToggle.Add_Unchecked({ Update-OperatingSystemSourceVisibility })
$LocalIsoCombo.Add_SelectionChanged({ Set-StartButtonState })
$OperatingSystemCombo.Add_SelectionChanged({ Update-OsResults })
$OSActivationCombo.Add_SelectionChanged({ Update-OsResults })
$OSEditionCombo.Add_SelectionChanged({ Update-OsResults })
$OSLanguageCodeCombo.Add_SelectionChanged({ Update-OsResults })
$script:SelectionConfirmed = $false

$StartButton.Add_Click({
    $TaskSequenceStepsGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true) | Out-Null
    $TaskSequenceStepsGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true) | Out-Null
    Save-TaskSequenceSteps -TaskSequenceName $script:CurrentTaskSequenceName -Steps $TaskSequenceStepsGrid.ItemsSource
    $script:SelectionConfirmed = $true
    $window.DialogResult = $true
    $window.Close()
})

Update-OsResults
Update-OperatingSystemSourceVisibility

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

    $LogsPath = "$env:TEMP\osdcloud-logs"
    if (-not (Test-Path -Path $LogsPath)) {
        New-Item -Path $LogsPath -ItemType Directory -Force | Out-Null
    }
    $global:OSDCloudDeploy | ConvertTo-Json | Out-File -FilePath "$LogsPath\OSDCloudDeploy.json" -Encoding utf8 -Width 2000 -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
}
