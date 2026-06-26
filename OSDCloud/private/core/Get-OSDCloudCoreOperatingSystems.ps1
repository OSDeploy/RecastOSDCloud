<#=================================================================================
    Get-OSDCloudCoreOperatingSystems
    ================================================================================
    - Retrieves all operating system records from Microsoft catalogs
        - Uses Get-CoreOperatingSystems records and extracts OS build, version,
            architecture, language, and activation information
    - Returns sorted array of operating system objects
    ================================================================================
    .SYNOPSIS
        Retrieves all operating system records from the OSDCloud catalog

    .DESCRIPTION
        Imports operating system metadata from Get-CoreOperatingSystems,
        then parses file names and catalog properties to extract OS build
        numbers, versions, architecture, language codes, and download
        information.

    .PARAMETER None
        This function does not accept parameters.

    .EXAMPLE
        PS C:\> Get-OSDCloudCoreOperatingSystems
        Returns all available operating system records

    .EXAMPLE
        PS C:\> Get-OSDCloudCoreOperatingSystems | Where-Object { $_.OSName -eq 'Windows 11' }
        Returns only Windows 11 operating systems

    .EXAMPLE
        PS C:\> Get-OSDCloudCoreOperatingSystems | Group-Object OperatingSystem
        Groups operating systems by major version

    .NOTES
        Author: OSDeploy
        Version: 1.0
        GitHub: https://github.com/OSDeploy

    .LINK
        https://www.osdeploy.com/
=================================================================================#>
function Get-OSDCloudCoreOperatingSystems {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param ()
    $ErrorActionPreference = 'Stop'
    $records = @()

    $mctRecords = Get-CoreOperatingSystems

    if (-not $mctRecords) {
        return $records
    }

    foreach ($node in ($mctRecords | Sort-Object FileName, LanguageCode, Architecture)) {
        Write-Verbose "[$(Get-Date -Format s)] [$($MyInvocation.MyCommand.Name)] Processing $($node.FileName)"

        if ([string]::IsNullOrWhiteSpace($node.FileName) -or $node.FileName.Length -lt 5) {
            continue
        }
            #=================================================
            #   OSBuild
            #   Get the OSBuild from the FileName
            $OSBuild = $node.FileName.Substring(0, 5)
            #=================================================
            #   OperatingSystem / OSName / OSVersion
            #   19045 = Windows 10 22H2
            #   22000 = Windows 11 21H2
            #   22621 = Windows 11 22H2
            #   22631 = Windows 11 23H2
            #   26100 = Windows 11 24H2
            #   26200 = Windows 11 25H2
            #   28000 = Windows 11 26H1
            switch ($OSBuild) {
                '19045' { $OperatingSystem = 'Windows 10 22H2'; $OSName = 'Windows 10'; $OSVersion = '22H2' }
                '22000' { $OperatingSystem = 'Windows 11 21H2'; $OSName = 'Windows 11'; $OSVersion = '21H2' }
                '22621' { $OperatingSystem = 'Windows 11 22H2'; $OSName = 'Windows 11'; $OSVersion = '22H2' }
                '22631' { $OperatingSystem = 'Windows 11 23H2'; $OSName = 'Windows 11'; $OSVersion = '23H2' }
                '26100' { $OperatingSystem = 'Windows 11 24H2'; $OSName = 'Windows 11'; $OSVersion = '24H2' }
                '26200' { $OperatingSystem = 'Windows 11 25H2'; $OSName = 'Windows 11'; $OSVersion = '25H2' }
                '28000' { $OperatingSystem = 'Windows 11 26H1'; $OSName = 'Windows 11'; $OSVersion = '26H1' }
                default { continue }
            }
            #=================================================
            #   OSBuildVersion
            #   Combination of <OSBuild>.<Sub>
            #   Extract from FileName
            #=================================================
            $fileNameParts = $node.FileName -split '\.'
            if ($fileNameParts.Count -lt 2) {
                continue
            }
            $OSBuildVersion = "$($fileNameParts[0]).$($fileNameParts[1])"
            #=================================================
            #   OSArchitecture
            #   Avoids confusion between x64 releases (amd64/arm64)
            #=================================================
            if ($node.Architecture -match 'x64') {
                $OSArchitecture = 'amd64'
            } elseif ($node.Architecture -match 'arm64') {
                $OSArchitecture = 'arm64'
            } else {
                $OSArchitecture = 'x86'
                continue
            }
            #=================================================
            #   OSActivation
            #=================================================
            if ($node.FileName -match 'clientconsumer_ret') {
                $OSActivation = 'Retail'
            }
            elseif ($node.FileName -match 'CLIENTBUSINESS_VOL') {
                $OSActivation = 'Volume'
            }
            else {
                $OSActivation = 'Unknown'
                continue
            }
            #=================================================
            #   Id
            #=================================================
            $Id = "$OperatingSystem $OSArchitecture $OSActivation $($node.LanguageCode) $OSBuildVersion"
            #=================================================
            #   ObjectProperties
            #=================================================
            $records += [pscustomobject]@{
                Id              = $Id
                OperatingSystem = $OperatingSystem
                OSName          = $OSName
                OSVersion       = $OSVersion
                OSArchitecture  = $OSArchitecture
                OSActivation    = $OSActivation
                OSLanguageCode  = $node.LanguageCode
                OSLanguage      = $node.Language
                OSBuild         = $OSBuild
                OSBuildVersion  = $OSBuildVersion
                # Architecture    = $node.Architecture
                Size            = $node.Size
                Sha1            = $node.Sha1
                Sha256          = $node.Sha256
                FileName        = $node.FileName
                FilePath        = $node.FilePath
                # IsRetailOnly    = $node.IsRetailOnly
            }
    }
    $records = $records | Sort-Object -Property FileName -Unique
    $records = $records | Sort-Object -Property @{Expression = { $_.OperatingSystem }; Descending = $true }, OSArchitecture, OSActivation, OSLanguageCode
    return $records
}
