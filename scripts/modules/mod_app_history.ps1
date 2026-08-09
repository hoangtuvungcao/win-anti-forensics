# ============================================================
# USB Windows History Cleaner - Module: App History & Timeline
# Xoa lich su ung dung, UserAssist, BAM/DAM, Timeline
# ============================================================

function Clear-AppHistory {
    <#
    .SYNOPSIS
    Xoa lich su ung dung, Windows Timeline, UserAssist, BAM/DAM
    #>
    param(
        [PSCustomObject[]]$Users,
        [bool]$DryRun = $false
    )

    Write-Log "XOA LICH SU UNG DUNG VA WINDOWS TIMELINE" -Level "HEADER"

    $totalDeleted = 0
    $errors = 0

    # ============================================================
    # 1. Xoa BAM/DAM (System-wide - Background Activity Moderator)
    # ============================================================

    Write-Log "Buoc 1: Xoa BAM/DAM (Background Activity Monitor)..." -Level "INFO"

    $bamPaths = @(
        "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings",
        "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings",
        "HKLM:\SYSTEM\CurrentControlSet\Services\dam\State\UserSettings",
        "HKLM:\SYSTEM\CurrentControlSet\Services\dam\UserSettings"
    )

    foreach ($bamPath in $bamPaths) {
        if (Test-Path $bamPath) {
            try {
                $sids = Get-ChildItem -Path $bamPath -ErrorAction SilentlyContinue
                foreach ($sid in $sids) {
                    $props = Get-ItemProperty -Path $sid.PSPath -ErrorAction SilentlyContinue
                    $propCount = 0
                    foreach ($prop in $props.PSObject.Properties) {
                        if ($prop.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSProvider", "PSDrive", "Version", "SequenceNumber")) {
                            Remove-ItemProperty -Path $sid.PSPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                            $propCount++
                        }
                    }
                    $totalDeleted += $propCount
                }
                Write-Log "Xoa BAM/DAM entries: $(Split-Path $bamPath -Leaf)" -Level "SUCCESS"
            } catch {
                $errors++
            }
        }
    }

    # ============================================================
    # 2. Xu ly theo tung User
    # ============================================================

    foreach ($user in $Users) {
        Write-LogSeparator
        Write-Log "Xu ly user: $($user.Name)..." -Level "INFO"

        $profilePath = $user.ProfilePath
        $regBase = Get-UserRegistryPath -User $user

        # --- UserAssist (theo doi ung dung da chay) ---
        if ($regBase) {
            Write-Log "Xoa UserAssist..." -Level "INFO"
            $userAssistPath = "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
            if (Test-Path $userAssistPath) {
                try {
                    $guids = Get-ChildItem -Path $userAssistPath -ErrorAction SilentlyContinue
                    $count = 0
                    foreach ($guid in $guids) {
                        $countPath = "$($guid.PSPath)\Count"
                        if (Test-Path $countPath) {
                            $props = Get-ItemProperty -Path $countPath -ErrorAction SilentlyContinue
                            foreach ($prop in $props.PSObject.Properties) {
                                if ($prop.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSProvider", "PSDrive")) {
                                    Remove-ItemProperty -Path $countPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                                    $count++
                                }
                            }
                        }
                    }
                    Write-Log "Xoa $count UserAssist entries" -Level "SUCCESS"
                    $totalDeleted += $count
                } catch {
                    $errors++
                }
            }

            # --- Compatibility Assistant ---
            Write-Log "Xoa Compatibility Assistant..." -Level "INFO"
            $compatPath = "$regBase\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store"
            if (Test-Path $compatPath) {
                try {
                    $props = Get-ItemProperty -Path $compatPath -ErrorAction SilentlyContinue
                    $count = 0
                    foreach ($prop in $props.PSObject.Properties) {
                        if ($prop.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSProvider", "PSDrive")) {
                            Remove-ItemProperty -Path $compatPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                            $count++
                        }
                    }
                    Write-Log "Xoa $count Compatibility entries" -Level "SUCCESS"
                    $totalDeleted += $count
                } catch {
                    $errors++
                }
            }

            # --- MUI Cache ---
            Write-Log "Xoa MUI Cache..." -Level "INFO"
            $muiCachePath = "$regBase\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
            if (Test-Path $muiCachePath) {
                try {
                    $props = Get-ItemProperty -Path $muiCachePath -ErrorAction SilentlyContinue
                    $count = 0
                    foreach ($prop in $props.PSObject.Properties) {
                        if ($prop.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSProvider", "PSDrive", "LangID")) {
                            Remove-ItemProperty -Path $muiCachePath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                            $count++
                        }
                    }
                    Write-Log "Xoa $count MUI Cache entries" -Level "SUCCESS"
                    $totalDeleted += $count
                } catch {
                    $errors++
                }
            }

            # --- Recent Apps ---
            Write-Log "Xoa Recent Apps..." -Level "INFO"
            $recentAppsPath = "$regBase\Software\Microsoft\Windows\CurrentVersion\Search\RecentApps"
            if (Test-Path $recentAppsPath) {
                try {
                    $items = Get-ChildItem -Path $recentAppsPath -ErrorAction SilentlyContinue
                    $count = ($items | Measure-Object).Count
                    $items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Log "Xoa $count Recent Apps entries" -Level "SUCCESS"
                    $totalDeleted += $count
                } catch {
                    $errors++
                }
            }

            # --- RDP History (Remote Desktop) ---
            Write-Log "Xoa RDP History..." -Level "INFO"
            $rdpPaths = @(
                "$regBase\Software\Microsoft\Terminal Server Client\Default",
                "$regBase\Software\Microsoft\Terminal Server Client\Servers"
            )

            foreach ($rdpPath in $rdpPaths) {
                if (Test-Path $rdpPath) {
                    try {
                        if ($rdpPath -like "*\Default") {
                            $props = Get-ItemProperty -Path $rdpPath -ErrorAction SilentlyContinue
                            foreach ($prop in $props.PSObject.Properties) {
                                if ($prop.Name -like "MRU*") {
                                    Remove-ItemProperty -Path $rdpPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                                    $totalDeleted++
                                }
                            }
                        } else {
                            Get-ChildItem -Path $rdpPath -ErrorAction SilentlyContinue |
                                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                            $totalDeleted++
                        }
                        Write-Log "Xoa RDP: $(Split-Path $rdpPath -Leaf)" -Level "SUCCESS"
                    } catch {
                        $errors++
                    }
                }
            }

            # --- Map Network Drive MRU ---
            $mapDrivePath = "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\Map Network Drive MRU"
            if (Test-Path $mapDrivePath) {
                try {
                    $props = Get-ItemProperty -Path $mapDrivePath -ErrorAction SilentlyContinue
                    foreach ($prop in $props.PSObject.Properties) {
                        if ($prop.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSProvider", "PSDrive")) {
                            Remove-ItemProperty -Path $mapDrivePath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                            $totalDeleted++
                        }
                    }
                    Write-Log "Xoa Map Network Drive MRU" -Level "SUCCESS"
                } catch {
                    $errors++
                }
            }

            Unload-UserRegistry -User $user
        }

        # --- Windows Timeline ---
        Write-Log "Xoa Windows Timeline..." -Level "INFO"
        $timelinePath = "$profilePath\AppData\Local\ConnectedDevicesPlatform"
        if (Test-Path $timelinePath) {
            try {
                $items = Get-ChildItem -Path $timelinePath -Recurse -ErrorAction SilentlyContinue
                $count = ($items | Measure-Object).Count
                Remove-Item -Path "$timelinePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Xoa $count Timeline items" -Level "SUCCESS"
                $totalDeleted += $count
            } catch {
                $errors++
            }
        }

        # --- PowerShell History ---
        Write-Log "Xoa PowerShell History..." -Level "INFO"
        $psHistoryPath = "$profilePath\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
        if (Test-Path $psHistoryPath) {
            try {
                Remove-Item -Path $psHistoryPath -Force -ErrorAction Stop
                Write-Log "Xoa PowerShell command history" -Level "SUCCESS"
                $totalDeleted++
            } catch {
                $errors++
            }
        }

        # --- Cortana / Windows Search History ---
        Write-Log "Xoa Cortana / Search History..." -Level "INFO"
        $cortanaPath = "$profilePath\AppData\Local\Packages"
        if (Test-Path $cortanaPath) {
            $cortanaPkgs = Get-ChildItem -Path $cortanaPath -Directory -Filter "Microsoft.Windows.Cortana*" -ErrorAction SilentlyContinue
            $searchPkgs = Get-ChildItem -Path $cortanaPath -Directory -Filter "Microsoft.Windows.Search*" -ErrorAction SilentlyContinue

            foreach ($pkg in ($cortanaPkgs + $searchPkgs)) {
                $localState = "$($pkg.FullName)\LocalState"
                if (Test-Path $localState) {
                    try {
                        Remove-Item -Path "$localState\*" -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Log "Xoa $($pkg.Name) data" -Level "SUCCESS"
                        $totalDeleted++
                    } catch { }
                }
            }
        }

        Write-LogSeparator
    }

    # Cap nhat stats
    Add-CleanStat -Category "RegistryKeysDeleted" -Count $totalDeleted
    Add-CleanStat -Category "Errors" -Count $errors

    Write-Log "Hoan tat xoa App History. Tong: $totalDeleted, Loi: $errors" -Level "INFO"
}
