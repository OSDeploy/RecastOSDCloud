function Get-OSDCloudCatalogSurface {
    <#
    .SYNOPSIS
        Retrieves the Microsoft Surface driver pack catalog, enriching entries from live download pages.

    .DESCRIPTION
        Loads the bundled microsoft.json catalog as the offline base. For entries that include an
        UpdatePage URL, the function scrapes the corresponding Microsoft download page to find the
        newest available MSI and updates FileName, Url, and ReleaseDate accordingly.
        Results are cached in $env:TEMP so subsequent calls within the same session skip network
        requests. Falls back to base JSON values when a page cannot be reached.

    .EXAMPLE
        Get-OSDCloudCatalogSurface

        Returns all Surface driver pack entries, with live URLs where available.

    .EXAMPLE
        Get-OSDCloudCatalogSurface -Verbose

        Returns all Surface driver pack entries with verbose progress output.

    .OUTPUTS
        PSCustomObject[]
        Objects with CatalogVersion, ReleaseDate, Name, Manufacturer, Model, SystemId, FileName,
        Url, OperatingSystem, OSArchitecture, and HashMD5 properties.

    .NOTES
        Base catalog: catalogs/driverpack/microsoft.json (bundled with the module)
        Temp cache:   $env:TEMP\osdcloud-driverpack-microsoft.json
    #>
    [CmdletBinding()]
    param ()

    begin {
        $Error.Clear()
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
        #=================================================
        # Paths
        $localCatalogPath = Join-Path (Get-OSDCloudModulePath) 'catalogs\driverpack\microsoft.json'
        $tempCatalogPath  = "$env:TEMP\osdcloud-driverpack-microsoft.json"
        #=================================================
        # Load from temp cache if available
        $useCache = $false
        if (Test-Path $tempCatalogPath) {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Loading cached catalog from $tempCatalogPath"
            $JsonCatalogContent = Get-Content -Path $tempCatalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $useCache = $true
        }
        else {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Loading base catalog from $localCatalogPath"
            $JsonCatalogContent = Get-Content -Path $localCatalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
        }

        if (-not $JsonCatalogContent) {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Failed to load Surface driver pack catalog"),
                'CatalogLoadFailed',
                [System.Management.Automation.ErrorCategory]::InvalidData,
                $localCatalogPath
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    process {
        #=================================================
        # Return cached results immediately
        #=================================================
        if ($useCache) {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Returning $($JsonCatalogContent.Count) entries from cache"
            $JsonCatalogContent
            return
        }

        #=================================================
        # Build enriched catalog from base JSON
        #=================================================
        $CatalogVersion    = Get-Date -Format yy.MM.dd
        $userAgent         = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
        $msiPattern        = 'https://download\.microsoft\.com/download/[^"''<>\s]+\.msi'
        $updatePageCache   = @{}

        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Building Surface driver pack catalog (CatalogVersion: $CatalogVersion)"

        # If a device OSDProduct is known, limit live UpdatePage checks to the matching entry only
        $osdProduct = if ($global:OSDCloudDevice -and $global:OSDCloudDevice.OSDProduct) { $global:OSDCloudDevice.OSDProduct } else { $null }
        if ($osdProduct) {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDProduct filter active: only fetching live data for SystemId matching '$osdProduct'"
        }

        $Results = foreach ($item in $JsonCatalogContent) {
            $releaseDate = $item.ReleaseDate
            $fileName    = $item.FileName
            $url         = $item.Url

            $isTargetDevice = (-not $osdProduct) -or ($item.SystemId -match [regex]::Escape($osdProduct))

            if ($item.UpdatePage -and $isTargetDevice) {
                $updatePage = $item.UpdatePage

                if ($updatePageCache.ContainsKey($updatePage)) {
                    $cached = $updatePageCache[$updatePage]
                    if (-not $cached.Error) {
                        $fileName    = $cached.FileName
                        $url         = $cached.Url
                        $releaseDate = $cached.ReleaseDate
                    }
                    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Cache hit for $($item.Model) -> $fileName"
                }
                else {
                    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Checking UpdatePage for $($item.Model): $updatePage"
                    try {
                        $response = Invoke-WebRequest -Uri $updatePage -UseBasicParsing -UserAgent $userAgent -MaximumRedirection 5 -ErrorAction Stop
                        $html     = $response.Content

                        $allMsi = @(
                            [regex]::Matches($html, $msiPattern) |
                                ForEach-Object { $_.Value } |
                                Select-Object -Unique
                        )

                        # Fallback: try the confirmation page if no MSI links on the details page
                        if ($allMsi.Count -eq 0) {
                            $pageId     = [System.Web.HttpUtility]::ParseQueryString(([uri]$updatePage).Query)['id']
                            $confirmUri = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=$pageId"
                            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] No MSI on details page, trying confirmation page: $confirmUri"
                            $response = Invoke-WebRequest -Uri $confirmUri -UseBasicParsing -UserAgent $userAgent -MaximumRedirection 5 -ErrorAction Stop
                            $html     = $response.Content
                            $allMsi   = @(
                                [regex]::Matches($html, $msiPattern) |
                                    ForEach-Object { $_.Value } |
                                    Select-Object -Unique
                            )
                        }

                        if ($allMsi.Count -gt 0) {
                            # Prefer Win11 MSIs; among those pick the highest OS build number in the filename
                            $win11Uris = @($allMsi | Where-Object { $_ -match 'Win11' })
                            $candidates = if ($win11Uris.Count -gt 0) { $win11Uris } else { $allMsi }
                            $bestUri = $candidates |
                                Sort-Object {
                                    if ($_ -match '_(\d{5})_') { [int]$Matches[1] } else { 0 }
                                } -Descending |
                                Select-Object -First 1

                            $newFileName = $bestUri -replace '.+/', ''

                            # Extract Date Published from HTML
                            $newDate = $null
                            $now     = [datetime]::UtcNow
                            foreach ($m in [regex]::Matches($html, 'Date Published[^:]*:[^\d]*(\d{1,2}/\d{1,2}/\d{4})')) {
                                try {
                                    $parsed = [datetime]::ParseExact($m.Groups[1].Value, 'M/d/yyyy', $null)
                                    if ($parsed.Year -ge 2015 -and $parsed -le $now.AddMonths(3)) {
                                        $newDate = $parsed.ToString('yy.MM.dd')
                                        break
                                    }
                                }
                                catch { }
                            }

                            $fileName    = $newFileName
                            $url         = $bestUri
                            $releaseDate = if ($newDate) { $newDate } else { $releaseDate }

                            $updatePageCache[$updatePage] = @{
                                Error       = $null
                                FileName    = $fileName
                                Url         = $url
                                ReleaseDate = $releaseDate
                            }
                            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Updated $($item.Model) -> $fileName [$releaseDate]"
                        }
                        else {
                            $updatePageCache[$updatePage] = @{ Error = 'No MSI links found' }
                            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] No MSI links found for $($item.Model), using base values"
                        }
                    }
                    catch {
                        $updatePageCache[$updatePage] = @{ Error = $_.Exception.Message }
                        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to check UpdatePage for $($item.Model): $($_.Exception.Message)"
                    }
                }
            }

            # Rebuild the Name bracket date with current releaseDate
            $baseName    = $item.Name -replace '\s*\[.*?\]$', ''
            $displayName = "$baseName [$releaseDate]"

            $objectProperties = [Ordered]@{
                CatalogVersion  = $CatalogVersion
                ReleaseDate     = $releaseDate
                Name            = $displayName
                Manufacturer    = $item.Manufacturer
                Model           = $item.Model
                SystemId        = $item.SystemId
                FileName        = $fileName
                Url             = $url
                OperatingSystem = $item.OperatingSystem
                OSArchitecture  = $item.OSArchitecture
                HashMD5         = $item.HashMD5
            }
            New-Object -TypeName PSObject -Property $objectProperties
        }

        #=================================================
        # Save enriched results to temp cache
        #=================================================
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Saving $($Results.Count) entries to $tempCatalogPath"
        $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $tempCatalogPath -Encoding utf8 -Force

        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Found $($Results.Count) Surface driver packs"
        $Results
    }

    end {
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    }
}
