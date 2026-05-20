[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $JsonPath
)

$userAgent  = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
$msiPattern = 'https://download\.microsoft\.com/download/[^"''<>\s]+\.msi'

function Select-BestMsi {
    param([string[]] $Uris)

    $win11      = @($Uris | Where-Object { $_ -match 'Win11' })
    $candidates = if ($win11.Count -gt 0) { $win11 } else { $Uris }

    $candidates |
        Sort-Object {
            if ($_ -match '_(\d{5})_') { [int]$Matches[1] } else { 0 }
        } -Descending |
        Select-Object -First 1
}

function ConvertTo-ReleaseDate {
    param([string] $Html)

    $now = [datetime]::UtcNow
    foreach ($m in [regex]::Matches($Html, 'Date Published[^:]*:[^\d]*(\d{1,2}/\d{1,2}/\d{4})')) {
        try {
            $parsed = [datetime]::ParseExact($m.Groups[1].Value, 'M/d/yyyy', $null)
            if ($parsed.Year -ge 2015 -and $parsed -le $now.AddMonths(3)) {
                return $parsed.ToString('yy.MM.dd')
            }
        } catch { }
    }
    return $null
}

function Invoke-DownloadPage {
    param([string] $Uri)

    return Invoke-WebRequest -Uri $Uri -UseBasicParsing -UserAgent $userAgent -MaximumRedirection 5
}

# ---------------------------------------------------------------------------

$jsonContent     = Get-Content -Path $JsonPath -Raw -Encoding UTF8
$entries         = $jsonContent | ConvertFrom-Json
$catalogVersion  = Get-Date -Format 'yy.MM.dd'
$changed         = $false
$updatePageCache = @{}

foreach ($entry in $entries) {
    if (-not $entry.UpdatePage) {
        Write-Host "Skipping $($entry.Model) (no UpdatePage)"
        continue
    }

    $updatePage = $entry.UpdatePage
    Write-Host "Checking $($entry.Model) [$updatePage]..."

    try {
        if (-not $updatePageCache.ContainsKey($updatePage)) {
            $response = Invoke-DownloadPage -Uri $updatePage
            $html     = $response.Content

            $allMsi = @(
                [regex]::Matches($html, $msiPattern) |
                    ForEach-Object { $_.Value } |
                    Select-Object -Unique
            )

            # Fallback: try the confirmation page if no MSI links on the details page
            if ($allMsi.Count -eq 0) {
                $pageId = if ($updatePage -match '[?&]id=(\d+)') { $Matches[1] } else { $null }
                if ($pageId) {
                    $confirmUri = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=$pageId"
                    Write-Host "  No MSI on details page, trying confirmation page: $confirmUri"
                    $response = Invoke-DownloadPage -Uri $confirmUri
                    $html     = $response.Content
                    $allMsi   = @(
                        [regex]::Matches($html, $msiPattern) |
                            ForEach-Object { $_.Value } |
                            Select-Object -Unique
                    )
                }
            }

            if ($allMsi.Count -gt 0) {
                $bestUri     = Select-BestMsi -Uris $allMsi
                $newFileName = $bestUri -replace '.+/', ''
                $newDate     = ConvertTo-ReleaseDate -Html $html

                $updatePageCache[$updatePage] = @{
                    Error       = $null
                    BestUri     = $bestUri
                    NewFileName = $newFileName
                    NewDate     = $newDate
                }
            } else {
                $updatePageCache[$updatePage] = @{ Error = 'No MSI links found' }
                Write-Warning "  No MSI links found for $($entry.Model) - using existing values"
            }
        }

        $cached = $updatePageCache[$updatePage]

        if ($cached.Error) {
            Write-Host "  Cache error: $($cached.Error)"
            continue
        }

        $bestUri     = $cached.BestUri
        $newFileName = $cached.NewFileName
        $newDate     = if ($cached.NewDate) { $cached.NewDate } else { $entry.ReleaseDate }

        if ($newFileName -ne $entry.FileName) {
            Write-Host "  UPDATED FileName : $($entry.FileName)"
            Write-Host "              ->     $newFileName"
            $entry.FileName = $newFileName
            $entry.Url      = $bestUri
            $changed        = $true
        }

        if ($newDate -ne $entry.ReleaseDate) {
            Write-Host "  UPDATED ReleaseDate: $($entry.ReleaseDate) -> $newDate"
            $entry.ReleaseDate = $newDate
            $baseName          = $entry.Name -replace '\s*\[.*?\]$', ''
            $entry.Name        = "$baseName [$newDate]"
            $changed           = $true
        }

        if ($changed -and $entry.CatalogVersion -ne $catalogVersion) {
            $entry.CatalogVersion = $catalogVersion
        }

    } catch {
        Write-Warning "  Failed to check $($entry.Model): $($_.Exception.Message)"
    }
}

# Rebuild with fixed field order
$ordered = $entries | ForEach-Object {
    [ordered] @{
        CatalogVersion  = $_.CatalogVersion
        ReleaseDate     = $_.ReleaseDate
        Name            = $_.Name
        Manufacturer    = $_.Manufacturer
        Model           = $_.Model
        SystemId        = $_.SystemId
        FileName        = $_.FileName
        Url             = $_.Url
        OperatingSystem = $_.OperatingSystem
        OSArchitecture  = $_.OSArchitecture
        HashMD5         = $_.HashMD5
        UpdatePage      = $_.UpdatePage
    }
}

$newJson = $ordered | ConvertTo-Json -Depth 10

if ($changed -or $newJson -ne $jsonContent) {
    Set-Content -Path $JsonPath -Value $newJson -Encoding utf8NoBOM
    Write-Host "Saved updated JSON -> $JsonPath"
}

# Emit output for GitHub Actions
$changedStr = $changed.ToString().ToLower()
if ($env:GITHUB_OUTPUT) {
    "changed=$changedStr" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
}
Write-Host "changed=$changedStr"
