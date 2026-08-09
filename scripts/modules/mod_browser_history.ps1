# ============================================================
# USB Windows History Cleaner - Module: Universal Browser Cleaner
# Tu dong phat hien VA xoa lich su TAT CA trinh duyet
# Ho tro: Chromium-based, Firefox-based, IE/Legacy
# ============================================================

# ============================================================
# Database tat ca trinh duyet biet den
# ============================================================

function Get-BrowserDatabase {
    <#
    .SYNOPSIS
    Tra ve danh sach tat ca trinh duyet va duong dan cua chung
    Chromium-based va Firefox-based
    #>

    return @(
        # ============ CHROMIUM-BASED ============
        @{
            Name = "Google Chrome"
            Type = "Chromium"
            LocalPath = "Google\Chrome\User Data"
            RoamingPath = $null
            ProcessName = "chrome"
        },
        @{
            Name = "Microsoft Edge"
            Type = "Chromium"
            LocalPath = "Microsoft\Edge\User Data"
            RoamingPath = $null
            ProcessName = "msedge"
        },
        @{
            Name = "Brave Browser"
            Type = "Chromium"
            LocalPath = "BraveSoftware\Brave-Browser\User Data"
            RoamingPath = $null
            ProcessName = "brave"
        },
        @{
            Name = "Opera"
            Type = "Chromium"
            LocalPath = "Opera Software\Opera Stable"
            RoamingPath = "Opera Software\Opera Stable"
            ProcessName = "opera"
            SingleProfile = $true  # Opera khong dung multi-profile nhu Chrome
        },
        @{
            Name = "Opera GX"
            Type = "Chromium"
            LocalPath = "Opera Software\Opera GX Stable"
            RoamingPath = "Opera Software\Opera GX Stable"
            ProcessName = "opera"
            SingleProfile = $true
        },
        @{
            Name = "Vivaldi"
            Type = "Chromium"
            LocalPath = "Vivaldi\User Data"
            RoamingPath = $null
            ProcessName = "vivaldi"
        },
        @{
            Name = "Coc Coc"
            Type = "Chromium"
            LocalPath = "CocCoc\Browser\User Data"
            RoamingPath = $null
            ProcessName = "browser"  # CocCoc dung ten process "browser"
        },
        @{
            Name = "Chromium"
            Type = "Chromium"
            LocalPath = "Chromium\User Data"
            RoamingPath = $null
            ProcessName = "chromium"
        },
        @{
            Name = "Yandex Browser"
            Type = "Chromium"
            LocalPath = "Yandex\YandexBrowser\User Data"
            RoamingPath = $null
            ProcessName = "browser"
        },
        @{
            Name = "SRWare Iron"
            Type = "Chromium"
            LocalPath = "SRWare Iron\User Data"
            RoamingPath = $null
            ProcessName = "iron"
        },
        @{
            Name = "Cent Browser"
            Type = "Chromium"
            LocalPath = "CentBrowser\User Data"
            RoamingPath = $null
            ProcessName = "chrome"
        },
        @{
            Name = "Comodo Dragon"
            Type = "Chromium"
            LocalPath = "Comodo\Dragon\User Data"
            RoamingPath = $null
            ProcessName = "dragon"
        },
        @{
            Name = "Epic Privacy Browser"
            Type = "Chromium"
            LocalPath = "Epic Privacy Browser\User Data"
            RoamingPath = $null
            ProcessName = "epic"
        },
        @{
            Name = "Torch Browser"
            Type = "Chromium"
            LocalPath = "Torch\User Data"
            RoamingPath = $null
            ProcessName = "torch"
        },
        @{
            Name = "UC Browser"
            Type = "Chromium"
            LocalPath = "UCBrowser\User Data_i18n\Default"
            RoamingPath = $null
            ProcessName = "UCBrowser"
            SingleProfile = $true
        },
        @{
            Name = "Whale Browser"
            Type = "Chromium"
            LocalPath = "Naver\Naver Whale\User Data"
            RoamingPath = $null
            ProcessName = "whale"
        },

        # ============ FIREFOX-BASED ============
        @{
            Name = "Mozilla Firefox"
            Type = "Firefox"
            LocalPath = "Mozilla\Firefox"
            RoamingPath = "Mozilla\Firefox"
            ProcessName = "firefox"
        },
        @{
            Name = "Waterfox"
            Type = "Firefox"
            LocalPath = "Waterfox"
            RoamingPath = "Waterfox"
            ProcessName = "waterfox"
        },
        @{
            Name = "Tor Browser"
            Type = "Firefox"
            LocalPath = $null
            RoamingPath = $null
            ProcessName = "firefox"
            SpecialPath = "Tor Browser\Browser\TorBrowser\Data\Browser"  # Relative to Desktop or install dir
        },
        @{
            Name = "LibreWolf"
            Type = "Firefox"
            LocalPath = "librewolf"
            RoamingPath = "librewolf"
            ProcessName = "librewolf"
        },
        @{
            Name = "Pale Moon"
            Type = "Firefox"
            LocalPath = "Moonchild Productions\Pale Moon"
            RoamingPath = "Moonchild Productions\Pale Moon"
            ProcessName = "palemoon"
        },
        @{
            Name = "Basilisk"
            Type = "Firefox"
            LocalPath = "Moonchild Productions\Basilisk"
            RoamingPath = "Moonchild Productions\Basilisk"
            ProcessName = "basilisk"
        },
        @{
            Name = "SeaMonkey"
            Type = "Firefox"
            LocalPath = "Mozilla\SeaMonkey"
            RoamingPath = "Mozilla\SeaMonkey"
            ProcessName = "seamonkey"
        },
        @{
            Name = "Thunderbird"
            Type = "Firefox"
            LocalPath = "Thunderbird"
            RoamingPath = "Thunderbird"
            ProcessName = "thunderbird"
        }
    )
}

# ============================================================
# Phat hien trinh duyet da cai dat
# ============================================================

function Find-InstalledBrowsers {
    param(
        [string]$UserProfilePath
    )

    $browserDB = Get-BrowserDatabase
    $found = @()

    foreach ($browser in $browserDB) {
        $exists = $false
        $dataPath = $null

        if ($browser.Type -eq "Chromium") {
            $localAppData = "$UserProfilePath\AppData\Local"
            $testPath = "$localAppData\$($browser.LocalPath)"
            if (Test-Path $testPath) {
                $exists = $true
                $dataPath = $testPath
            }

            # Kiem tra ca Roaming path (Opera)
            if (-not $exists -and $browser.RoamingPath) {
                $roamingPath = "$UserProfilePath\AppData\Roaming\$($browser.RoamingPath)"
                if (Test-Path $roamingPath) {
                    $exists = $true
                    $dataPath = $roamingPath
                }
            }
        }
        elseif ($browser.Type -eq "Firefox") {
            if ($browser.SpecialPath) {
                # Tor Browser - kiem tra nhieu vi tri
                $torPaths = @(
                    "$UserProfilePath\Desktop\$($browser.SpecialPath)",
                    "$UserProfilePath\Downloads\$($browser.SpecialPath)",
                    "${env:ProgramFiles}\$($browser.SpecialPath)",
                    "${env:ProgramFiles(x86)}\$($browser.SpecialPath)"
                )
                foreach ($tp in $torPaths) {
                    if (Test-Path $tp) {
                        $exists = $true
                        $dataPath = $tp
                        break
                    }
                }
            } else {
                $roamingPath = "$UserProfilePath\AppData\Roaming\$($browser.RoamingPath)"
                if (Test-Path $roamingPath) {
                    $profilesIni = "$roamingPath\profiles.ini"
                    if (Test-Path $profilesIni) {
                        $exists = $true
                        $dataPath = $roamingPath
                    }
                }
            }
        }

        if ($exists) {
            $found += @{
                Name = $browser.Name
                Type = $browser.Type
                DataPath = $dataPath
                ProcessName = $browser.ProcessName
                SingleProfile = [bool]$browser.SingleProfile
                LocalPath = $browser.LocalPath
                UserProfile = $UserProfilePath
            }
        }
    }

    return $found
}

# ============================================================
# Xoa Chromium-based browser
# ============================================================

function Clear-ChromiumBrowser {
    param(
        [hashtable]$Browser,
        [bool]$DryRun = $false
    )

    $deleted = 0
    $basePath = $Browser.DataPath

    # Tim tat ca profiles
    $profiles = @()
    if ($Browser.SingleProfile) {
        $profiles = @($basePath)
    } else {
        $profiles = @("$basePath\Default")
        $profileDirs = Get-ChildItem -Path $basePath -Directory -Filter "Profile *" -ErrorAction SilentlyContinue
        if ($profileDirs) {
            $profiles += $profileDirs | ForEach-Object { $_.FullName }
        }
        # Guest Profile
        if (Test-Path "$basePath\Guest Profile") {
            $profiles += "$basePath\Guest Profile"
        }
        # System Profile
        if (Test-Path "$basePath\System Profile") {
            $profiles += "$basePath\System Profile"
        }
    }

    # Files can xoa trong moi profile
    $filesToDelete = @(
        "History", "History-journal",
        "Visited Links",
        "Top Sites", "Top Sites-journal",
        "Web Data", "Web Data-journal",
        "Cookies", "Cookies-journal",
        "Shortcuts", "Shortcuts-journal",
        "Network Action Predictor", "Network Action Predictor-journal",
        "Favicons", "Favicons-journal",
        "Last Session", "Last Tabs",
        "Current Session", "Current Tabs",
        "QuotaManager", "QuotaManager-journal",
        "Reporting and NEL", "Reporting and NEL-journal",
        "TransportSecurity",
        "Trust Tokens", "Trust Tokens-journal",
        "Affiliation Database", "Affiliation Database-journal",
        "heavy_ad_intervention_opt_out.db",
        "optimization_guide_hint_cache.db",
        "PreferredApps",
        "Download Metadata",
        "DIPS",
        "Segmentation Platform",
        "commerce_subscription_db", "commerce_subscription_db-journal",
        "AutofillStrikeDatabase", "AutofillStrikeDatabase-journal",
        "Site Characteristics Database", "Site Characteristics Database-journal"
    )

    # Directories can xoa
    $dirsToDelete = @(
        "Cache", "Code Cache", "GPUCache",
        "Service Worker\CacheStorage",
        "Service Worker\ScriptCache",
        "Session Storage",
        "Local Storage\leveldb",
        "IndexedDB",
        "blob_storage",
        "databases",
        "shared_proto_db",
        "VideoDecodeStats",
        "GCM Store",
        "BudgetDatabase",
        "coupon_db",
        "Download Service\Files",
        "Feature Engagement Tracker",
        "optimization_guide_model_metadata",
        "optimization_guide_prediction_model_downloads"
    )

    foreach ($profilePath in $profiles) {
        if (-not (Test-Path $profilePath)) { continue }

        # Xoa files
        foreach ($file in $filesToDelete) {
            $filePath = "$profilePath\$file"
            if (Test-Path $filePath) {
                if ($DryRun) {
                    Write-Log "[DRY-RUN] Se xoa: $filePath" -Level "DETAIL"
                } else {
                    try {
                        Remove-Item -Path $filePath -Recurse -Force -ErrorAction SilentlyContinue
                        $deleted++
                    } catch { }
                }
            }
        }

        # Xoa directories
        foreach ($dir in $dirsToDelete) {
            $dirPath = "$profilePath\$dir"
            if (Test-Path $dirPath) {
                if ($DryRun) {
                    Write-Log "[DRY-RUN] Se xoa dir: $dirPath" -Level "DETAIL"
                } else {
                    try {
                        Remove-Item -Path "$dirPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                        $deleted++
                    } catch { }
                }
            }
        }
    }

    # Xoa shared caches
    $sharedDirs = @(
        "ShaderCache", "GrShaderCache", "GraphiteDawnCache",
        "component_crx_cache", "CertificateRevocation",
        "ZxcvbnData", "MEIPreload", "OnDeviceHeadSuggestModel",
        "SafetyTips", "SSLErrorAssistant", "Subresource Filter",
        "OriginTrials", "hyphen-data", "pnacl"
    )

    foreach ($dir in $sharedDirs) {
        $dirPath = "$basePath\$dir"
        if (Test-Path $dirPath) {
            if (-not $DryRun) {
                Remove-Item -Path "$dirPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                $deleted++
            }
        }
    }

    # Xoa Crashpad
    $crashpadPath = "$basePath\Crashpad"
    if (Test-Path $crashpadPath) {
        if (-not $DryRun) {
            Remove-Item -Path "$crashpadPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            $deleted++
        }
    }

    return $deleted
}

# ============================================================
# Xoa Firefox-based browser
# ============================================================

function Clear-FirefoxBrowser {
    param(
        [hashtable]$Browser,
        [bool]$DryRun = $false
    )

    $deleted = 0
    $basePath = $Browser.DataPath

    # Tim tat ca Firefox profiles
    $profilesPath = "$basePath\Profiles"
    if (-not (Test-Path $profilesPath)) {
        $profilesPath = $basePath
    }

    $ffProfiles = Get-ChildItem -Path $profilesPath -Directory -ErrorAction SilentlyContinue
    if (-not $ffProfiles) {
        $ffProfiles = @([PSCustomObject]@{ FullName = $basePath })
    }

    # Files can xoa
    $filesToDelete = @(
        "places.sqlite", "places.sqlite-wal", "places.sqlite-shm",
        "cookies.sqlite", "cookies.sqlite-wal", "cookies.sqlite-shm",
        "formhistory.sqlite", "formhistory.sqlite-wal",
        "downloads.sqlite", "downloads.sqlite-wal",
        "permissions.sqlite", "permissions.sqlite-wal",
        "content-prefs.sqlite", "content-prefs.sqlite-wal",
        "webappsstore.sqlite", "webappsstore.sqlite-wal",
        "favicons.sqlite", "favicons.sqlite-wal",
        "storage-sync-v2.sqlite", "storage-sync-v2.sqlite-wal",
        "protections.sqlite",
        "sessionstore.jsonlz4",
        "sessionCheckpoints.json",
        "SiteSecurityServiceState.txt",
        "SecurityPreloadState.txt",
        "search.json.mozlz4",
        "serviceworker.txt",
        "shield-preference-experiments.json"
    )

    # Directories can xoa
    $dirsToDelete = @(
        "sessionstore-backups",
        "cache2",
        "startupCache",
        "thumbnails",
        "jumpListCache",
        "saved-telemetry-pings",
        "datareporting",
        "crashes",
        "minidumps",
        "storage\default",
        "storage\temporary",
        "shader-cache",
        "security_state"
    )

    foreach ($profile in $ffProfiles) {
        $profilePath = if ($profile -is [PSCustomObject]) { $profile.FullName } else { $profile.FullName }
        if (-not (Test-Path $profilePath)) { continue }

        # Xoa files
        foreach ($file in $filesToDelete) {
            $filePath = "$profilePath\$file"
            if (Test-Path $filePath) {
                if ($DryRun) {
                    Write-Log "[DRY-RUN] Se xoa: $filePath" -Level "DETAIL"
                } else {
                    try {
                        Remove-Item -Path $filePath -Recurse -Force -ErrorAction SilentlyContinue
                        $deleted++
                    } catch { }
                }
            }
        }

        # Xoa directories
        foreach ($dir in $dirsToDelete) {
            $dirPath = "$profilePath\$dir"
            if (Test-Path $dirPath) {
                if (-not $DryRun) {
                    Remove-Item -Path "$dirPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $deleted++
                }
            }
        }
    }

    # Xoa local cache (Firefox luu cache rieng)
    if ($Browser.LocalPath) {
        $localCachePath = "$($Browser.UserProfile)\AppData\Local\$($Browser.LocalPath)\Profiles"
        if (Test-Path $localCachePath) {
            $cacheProfiles = Get-ChildItem -Path $localCachePath -Directory -ErrorAction SilentlyContinue
            foreach ($cp in $cacheProfiles) {
                $cache2 = "$($cp.FullName)\cache2"
                if (Test-Path $cache2) {
                    if (-not $DryRun) {
                        Remove-Item -Path "$cache2\*" -Recurse -Force -ErrorAction SilentlyContinue
                        $deleted++
                    }
                }
                $startupCache = "$($cp.FullName)\startupCache"
                if (Test-Path $startupCache) {
                    if (-not $DryRun) {
                        Remove-Item -Path "$startupCache\*" -Recurse -Force -ErrorAction SilentlyContinue
                        $deleted++
                    }
                }
            }
        }
    }

    return $deleted
}

# ============================================================
# Xoa IE / Legacy Edge
# ============================================================

function Clear-IEHistory {
    param(
        [string]$UserProfilePath,
        [string]$RegBase,
        [bool]$DryRun = $false
    )

    $deleted = 0

    $iePaths = @(
        "$UserProfilePath\AppData\Local\Microsoft\Windows\INetCache",
        "$UserProfilePath\AppData\Local\Microsoft\Windows\INetCookies",
        "$UserProfilePath\AppData\Local\Microsoft\Windows\Temporary Internet Files",
        "$UserProfilePath\AppData\Local\Microsoft\Windows\History",
        "$UserProfilePath\AppData\Local\Microsoft\Windows\WebCache",
        "$UserProfilePath\AppData\Local\Microsoft\Internet Explorer\Recovery",
        "$UserProfilePath\AppData\Local\Microsoft\Internet Explorer\Tiles",
        "$UserProfilePath\AppData\Local\Microsoft\Internet Explorer\imagestore",
        "$UserProfilePath\AppData\Local\Microsoft\Internet Explorer\DOMStore",
        "$UserProfilePath\Favorites\Links"
    )

    foreach ($iePath in $iePaths) {
        if (Test-Path $iePath) {
            if ($DryRun) {
                Write-Log "[DRY-RUN] Se xoa: $iePath" -Level "DETAIL"
            } else {
                try {
                    Remove-Item -Path "$iePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $deleted++
                } catch { }
            }
        }
    }

    # IE Registry
    if ($RegBase) {
        $ieRegPaths = @(
            "$RegBase\Software\Microsoft\Internet Explorer\TypedURLs",
            "$RegBase\Software\Microsoft\Internet Explorer\TypedURLsTime",
            "$RegBase\Software\Microsoft\Internet Explorer\Main\Window_Placement",
            "$RegBase\Software\Microsoft\Internet Explorer\IntelliForms",
            "$RegBase\Software\Microsoft\Internet Explorer\LowRegistry\DOMStorage"
        )

        foreach ($regPath in $ieRegPaths) {
            if (Test-Path $regPath) {
                if (-not $DryRun) {
                    try {
                        Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue |
                            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                        $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
                        if ($props) {
                            foreach ($prop in $props.PSObject.Properties) {
                                if ($prop.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSProvider", "PSDrive")) {
                                    Remove-ItemProperty -Path $regPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                                    $deleted++
                                }
                            }
                        }
                    } catch { }
                }
            }
        }
    }

    return $deleted
}

# ============================================================
# HAM CHINH: Xoa lich su TAT CA browser
# ============================================================

function Clear-BrowserHistory {
    param(
        [PSCustomObject[]]$Users,
        [bool]$DryRun = $false
    )

    Write-Log "XOA LICH SU TRINH DUYET (TAT CA BROWSERS)" -Level "HEADER"

    $totalDeleted = 0
    $errors = 0
    $allBrowsersFound = @()

    # ============================================================
    # Buoc 1: Dong tat ca trinh duyet truoc khi xoa
    # ============================================================

    if (-not $DryRun) {
        Write-Log "Dang dong cac trinh duyet truoc khi xoa..." -Level "WARNING"

        $browserDB = Get-BrowserDatabase
        $processNames = $browserDB | ForEach-Object { $_.ProcessName } | Select-Object -Unique

        foreach ($procName in $processNames) {
            $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if ($procs) {
                Write-Log "Dong $procName ($($procs.Count) processes)..." -Level "INFO"
                $procs | Stop-Process -Force -ErrorAction SilentlyContinue
            }
        }
        Start-Sleep -Seconds 2
    }

    # ============================================================
    # Buoc 2: Quet va xoa theo tung user
    # ============================================================

    foreach ($user in $Users) {
        Write-LogSeparator
        Write-Log "Quet browser cho user: $($user.Name)..." -Level "INFO"

        $profilePath = $user.ProfilePath
        $browsers = Find-InstalledBrowsers -UserProfilePath $profilePath

        if ($browsers.Count -eq 0) {
            Write-Log "Khong tim thay trinh duyet nao cho user $($user.Name)" -Level "DETAIL"
            continue
        }

        Write-Log "Tim thay $($browsers.Count) trinh duyet:" -Level "SUCCESS"
        foreach ($b in $browsers) {
            Write-Log "  - $($b.Name)" -Level "DETAIL"
            $allBrowsersFound += $b.Name
        }

        # Xoa theo tung browser
        foreach ($browser in $browsers) {
            Write-Log "Xoa $($browser.Name)..." -Level "INFO"

            try {
                if ($browser.Type -eq "Chromium") {
                    $count = Clear-ChromiumBrowser -Browser $browser -DryRun $DryRun
                }
                elseif ($browser.Type -eq "Firefox") {
                    $count = Clear-FirefoxBrowser -Browser $browser -DryRun $DryRun
                }

                $totalDeleted += $count
                $action = if ($DryRun) { "[DRY-RUN] Se xoa" } else { "Xoa" }
                Write-Log "$action $($browser.Name): $count items" -Level "SUCCESS"
            } catch {
                Write-Log "Loi xoa $($browser.Name): $($_.Exception.Message)" -Level "ERROR"
                $errors++
            }
        }

        # Xoa IE/Legacy cho moi user
        Write-Log "Xoa Internet Explorer / Legacy Edge..." -Level "INFO"
        $regBase = Get-UserRegistryPath -User $user
        $ieCount = Clear-IEHistory -UserProfilePath $profilePath -RegBase $regBase -DryRun $DryRun
        $totalDeleted += $ieCount
        if ($regBase) { Unload-UserRegistry -User $user }

        Write-LogSeparator
    }

    # ============================================================
    # Tong ket
    # ============================================================

    $uniqueBrowsers = $allBrowsersFound | Select-Object -Unique
    Write-Log "Trinh duyet da xu ly: $($uniqueBrowsers -join ', ')" -Level "INFO"

    Add-CleanStat -Category "FilesDeleted" -Count $totalDeleted
    Add-CleanStat -Category "Errors" -Count $errors

    Write-Log "Hoan tat xoa Browser History. Tong: $totalDeleted, Loi: $errors" -Level "INFO"
}
