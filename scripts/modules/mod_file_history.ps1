# ============================================================
# USB Windows History Cleaner - Module: File History
# Xoa lich su truy cap file, thu muc, recent, prefetch
# ============================================================

function Clear-FileHistory {
    <#
    .SYNOPSIS
    Xoa lich su truy cap file cho cac user duoc chon
    #>
    param(
        [PSCustomObject[]]$Users,
        [bool]$DryRun = $false
    )

    Write-Log "XOA LICH SU TRUY CAP FILE VA THU MUC" -Level "HEADER"

    $totalDeleted = 0
    $errors = 0

    # ============================================================
    # 1. Xoa Prefetch (System-wide)
    # ============================================================

    Write-Log "Buoc 1: Xoa Prefetch files..." -Level "INFO"

    $prefetchPath = "$env:SystemRoot\Prefetch"
    if (Test-Path $prefetchPath) {
        try {
            $items = Get-ChildItem -Path $prefetchPath -File -ErrorAction SilentlyContinue
            $count = ($items | Measure-Object).Count
            Remove-Item -Path "$prefetchPath\*" -Force -ErrorAction SilentlyContinue
            Write-Log "Xoa $count prefetch files" -Level "SUCCESS"
            $totalDeleted += $count
        } catch {
            Write-Log "Loi xoa Prefetch: $($_.Exception.Message)" -Level "WARNING"
            $errors++
        }
    }

    # ============================================================
    # 2. Xoa System Temp
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 2: Xoa System Temp files..." -Level "INFO"

    $systemTemp = "$env:SystemRoot\Temp"
    if (Test-Path $systemTemp) {
        try {
            $items = Get-ChildItem -Path $systemTemp -Recurse -ErrorAction SilentlyContinue
            $count = ($items | Measure-Object).Count
            Remove-Item -Path "$systemTemp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Xoa $count system temp items" -Level "SUCCESS"
            $totalDeleted += $count
        } catch {
            $errors++
        }
    }

    # ============================================================
    # 3. Xoa theo tung User
    # ============================================================

    foreach ($user in $Users) {
        Write-LogSeparator
        Write-Log "Xu ly user: $($user.Name)..." -Level "INFO"

        $profilePath = $user.ProfilePath

        # --- Recent Files ---
        $recentPaths = @(
            "$profilePath\AppData\Roaming\Microsoft\Windows\Recent",
            "$profilePath\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations",
            "$profilePath\AppData\Roaming\Microsoft\Windows\Recent\CustomDestinations"
        )

        foreach ($recentPath in $recentPaths) {
            if (Test-Path $recentPath) {
                try {
                    $items = Get-ChildItem -Path $recentPath -File -ErrorAction SilentlyContinue
                    $count = ($items | Measure-Object).Count
                    Remove-Item -Path "$recentPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Log "Xoa $count recent files: $(Split-Path $recentPath -Leaf)" -Level "SUCCESS"
                    $totalDeleted += $count
                } catch {
                    $errors++
                }
            }
        }

        # --- User Temp ---
        $userTemp = "$profilePath\AppData\Local\Temp"
        if (Test-Path $userTemp) {
            try {
                $items = Get-ChildItem -Path $userTemp -Recurse -ErrorAction SilentlyContinue
                $count = ($items | Measure-Object).Count
                Remove-Item -Path "$userTemp\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Xoa $count user temp items" -Level "SUCCESS"
                $totalDeleted += $count
            } catch {
                $errors++
            }
        }

        # --- Thumbnail Cache ---
        $thumbPath = "$profilePath\AppData\Local\Microsoft\Windows\Explorer"
        if (Test-Path $thumbPath) {
            try {
                $thumbFiles = Get-ChildItem -Path $thumbPath -Filter "thumbcache_*" -ErrorAction SilentlyContinue
                $count = ($thumbFiles | Measure-Object).Count
                $thumbFiles | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-Log "Xoa $count thumbnail cache files" -Level "SUCCESS"
                $totalDeleted += $count

                # Icon Cache
                $iconCache = "$profilePath\AppData\Local\IconCache.db"
                if (Test-Path $iconCache) {
                    Remove-Item -Path $iconCache -Force -ErrorAction SilentlyContinue
                    $totalDeleted++
                }
            } catch {
                $errors++
            }
        }

        # --- Registry: Recent Docs, MRU, etc. ---
        $regBase = Get-UserRegistryPath -User $user
        if ($regBase) {
            $registryPathsToDelete = @(
                "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
                "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU",
                "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU",
                "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRULegacy",
                "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
                "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths",
                "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"
            )

            foreach ($regPath in $registryPathsToDelete) {
                if (Test-Path $regPath) {
                    try {
                        # Xoa cac subkeys
                        Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue |
                            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

                        # Xoa cac values
                        $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
                        if ($props) {
                            foreach ($prop in $props.PSObject.Properties) {
                                if ($prop.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSProvider", "PSDrive")) {
                                    Remove-ItemProperty -Path $regPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                                    $totalDeleted++
                                }
                            }
                        }

                        Write-Log "Xoa Registry: $(Split-Path $regPath -Leaf)" -Level "SUCCESS"
                        $totalDeleted++
                    } catch {
                        Write-Log "Loi xoa registry: $(Split-Path $regPath -Leaf)" -Level "WARNING"
                        $errors++
                    }
                }
            }

            # Unload registry neu la user khac
            Unload-UserRegistry -User $user
        }
    }

    # Cap nhat stats
    Add-CleanStat -Category "FilesDeleted" -Count $totalDeleted
    Add-CleanStat -Category "Errors" -Count $errors

    Write-LogSeparator
    Write-Log "Hoan tat xoa File History. Tong: $totalDeleted, Loi: $errors" -Level "INFO"
}
