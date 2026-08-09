# ============================================================
# USB Windows History Cleaner - Module: System Cache
# Xoa DNS cache, ARP, Font cache, Windows Update,
# Pagefile, VSS, Hiberfil, va cac cache he thong khac
# Compatible with PS 3.0, 4.0, 5.1, 7.x
# ============================================================

function Clear-SystemCache {
    param(
        [PSCustomObject[]]$Users,
        [bool]$DryRun = $false
    )

    $ErrorActionPreference = "SilentlyContinue"

    Write-Log "XOA SYSTEM CACHE & DAU VET NANG CAO" -Level "HEADER"

    $totalDeleted = 0
    $errors = 0

    # ============================================================
    # 1. Flush DNS Cache
    # ============================================================

    Write-Log "Buoc 1: Flush DNS Cache..." -Level "INFO"
    if (-not $DryRun) {
        try {
            ipconfig /flushdns 2>$null | Out-Null
            Write-Log "Flush DNS Cache thanh cong" -Level "SUCCESS"
            $totalDeleted++
        } catch { $errors++ }
    } else {
        Write-Log "[DRY-RUN] Se flush DNS Cache" -Level "DETAIL"
    }

    # ============================================================
    # 2. Xoa ARP Cache
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 2: Xoa ARP Cache..." -Level "INFO"
    if (-not $DryRun) {
        try {
            arp -d * 2>$null
            netsh interface ip delete arpcache 2>$null | Out-Null
            Write-Log "Xoa ARP Cache thanh cong" -Level "SUCCESS"
            $totalDeleted++
        } catch { $errors++ }
    }

    # ============================================================
    # 3. Xoa Font Cache
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 3: Xoa Font Cache..." -Level "INFO"

    $fontCachePaths = @(
        "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\FontCache",
        "$env:SystemRoot\System32\FNTCACHE.DAT"
    )

    foreach ($path in $fontCachePaths) {
        if (Test-Path $path) {
            if (-not $DryRun) {
                try {
                    Stop-Service -Name "FontCache" -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Milliseconds 500

                    if ((Get-Item $path).PSIsContainer) {
                        Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                    } else {
                        Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
                    }

                    Start-Service -Name "FontCache" -ErrorAction SilentlyContinue
                    Write-Log "Xoa font cache: $(Split-Path $path -Leaf)" -Level "SUCCESS"
                    $totalDeleted++
                } catch {
                    Start-Service -Name "FontCache" -ErrorAction SilentlyContinue
                    $errors++
                }
            }
        }
    }

    # ============================================================
    # 4. Xoa Windows Update Cache
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 4: Xoa Windows Update Cache..." -Level "INFO"

    $wuPaths = @(
        "$env:SystemRoot\SoftwareDistribution\Download",
        "$env:SystemRoot\SoftwareDistribution\DataStore\Logs"
    )

    if (-not $DryRun) {
        try {
            Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1

            foreach ($wuPath in $wuPaths) {
                if (Test-Path $wuPath) {
                    $items = Get-ChildItem -Path $wuPath -Recurse -ErrorAction SilentlyContinue
                    $count = ($items | Measure-Object).Count
                    Remove-Item -Path "$wuPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Log "Xoa $count WU items: $(Split-Path $wuPath -Leaf)" -Level "SUCCESS"
                    $totalDeleted += $count
                }
            }

            Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        } catch {
            Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
            $errors++
        }
    }

    # ============================================================
    # 5. Xoa Windows Installer Cache
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 5: Xoa Windows Installer temp files..." -Level "INFO"

    $installerTempPath = "$env:SystemRoot\Installer\`$PatchCache`$"
    if (Test-Path $installerTempPath) {
        if (-not $DryRun) {
            try {
                Remove-Item -Path "$installerTempPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Xoa Installer patch cache" -Level "SUCCESS"
                $totalDeleted++
            } catch { $errors++ }
        }
    }

    # ============================================================
    # 6. Xoa Delivery Optimization Cache
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 6: Xoa Delivery Optimization Cache..." -Level "INFO"

    if (-not $DryRun) {
        try {
            if (Get-Command Delete-DeliveryOptimizationCache -ErrorAction SilentlyContinue) {
                Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue
            } else {
                $doPath = "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization"
                if (Test-Path $doPath) {
                    Remove-Item -Path "$doPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            Write-Log "Xoa Delivery Optimization Cache" -Level "SUCCESS"
            $totalDeleted++
        } catch { $errors++ }
    }

    # ============================================================
    # 7. Xoa Windows Store Cache
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 7: Xoa Windows Store Cache..." -Level "INFO"

    foreach ($user in $Users) {
        $storeCachePaths = @(
            "$($user.ProfilePath)\AppData\Local\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalCache",
            "$($user.ProfilePath)\AppData\Local\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\AC"
        )

        foreach ($scPath in $storeCachePaths) {
            if (Test-Path $scPath) {
                if (-not $DryRun) {
                    Remove-Item -Path "$scPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $totalDeleted++
                }
            }
        }
    }

    if (-not $DryRun) {
        if (Test-Path "$env:SystemRoot\System32\wsreset.exe") {
            try { wsreset.exe 2>$null } catch { }
        }
    }
    Write-Log "Xoa Windows Store Cache" -Level "SUCCESS"

    # ============================================================
    # 8. Xoa Scheduled Tasks logs
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 8: Xoa Scheduled Tasks logs..." -Level "INFO"

    $schedLogPaths = @(
        "$env:SystemRoot\System32\LogFiles\Scm",
        "$env:SystemRoot\System32\LogFiles\SQM"
    )

    foreach ($slPath in $schedLogPaths) {
        if (Test-Path $slPath) {
            if (-not $DryRun) {
                Remove-Item -Path "$slPath\*" -Force -ErrorAction SilentlyContinue
                $totalDeleted++
            }
        }
    }
    Write-Log "Xoa Scheduled Tasks logs" -Level "SUCCESS"

    # ============================================================
    # 9. Xoa Volume Shadow Copies (VSS)
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 9: Xoa Volume Shadow Copies..." -Level "INFO"

    if (-not $DryRun) {
        try {
            vssadmin delete shadows /all /quiet 2>$null | Out-Null
            Write-Log "Xoa tat ca Volume Shadow Copies" -Level "SUCCESS"
            $totalDeleted++
        } catch {
            Write-Log "Khong the xoa VSS (co the khong co shadow copies)" -Level "DETAIL"
        }
    }

    # ============================================================
    # 10. Xoa Windows.old (neu co)
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 10: Kiem tra Windows.old..." -Level "INFO"

    $windowsOldPath = "$env:SystemDrive\Windows.old"
    if (Test-Path $windowsOldPath) {
        Write-Host ""
        $delOld = Read-Host "  Tim thay Windows.old. Xoa? (Y/N, mac dinh: N)"
        if ($delOld -eq "Y" -or $delOld -eq "y") {
            if (-not $DryRun) {
                try {
                    takeown /F "$windowsOldPath" /R /A /D Y 2>$null | Out-Null
                    icacls "$windowsOldPath" /grant administrators:F /T 2>$null | Out-Null
                    Remove-Item -Path $windowsOldPath -Recurse -Force -ErrorAction Stop
                    Write-Log "Xoa Windows.old thanh cong" -Level "SUCCESS"
                    $totalDeleted++
                } catch {
                    Write-Log "Khong the xoa Windows.old" -Level "WARNING"
                    $errors++
                }
            }
        }
    } else {
        Write-Log "Khong co Windows.old" -Level "DETAIL"
    }

    # ============================================================
    # 11. Xoa BITS Transfer History
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 11: Xoa BITS Transfer jobs..." -Level "INFO"

    if (-not $DryRun) {
        try {
            if (Get-Command Get-BitsTransfer -ErrorAction SilentlyContinue) {
                Get-BitsTransfer -AllUsers -ErrorAction SilentlyContinue |
                    Remove-BitsTransfer -ErrorAction SilentlyContinue
                Write-Log "Xoa BITS transfer history" -Level "SUCCESS"
                $totalDeleted++
            }
        } catch { }
    }

    # ============================================================
    # 12. Xoa Print Spooler History
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 12: Xoa Print Spooler History..." -Level "INFO"

    $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS"
    if (Test-Path $spoolPath) {
        if (-not $DryRun) {
            try {
                Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 500
                Remove-Item -Path "$spoolPath\*" -Force -ErrorAction SilentlyContinue
                Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
                Write-Log "Xoa Print Spooler queue" -Level "SUCCESS"
                $totalDeleted++
            } catch {
                Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
            }
        }
    }

    # ============================================================
    # 13. Xoa Network Credentials
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 13: Xoa Network Credentials (Cached)..." -Level "INFO"

    if (-not $DryRun) {
        try {
            cmdkey /list 2>$null | Select-String "Target:" | ForEach-Object {
                $target = ($_ -replace ".*Target:\s*", "").Trim()
                if ($target) {
                    cmdkey /delete:$target 2>$null | Out-Null
                    $totalDeleted++
                }
            }
            Write-Log "Xoa Network Credentials" -Level "SUCCESS"
        } catch { $errors++ }
    }

    # ============================================================
    # 14. Disable Pagefile Zeroing config
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 14: Cau hinh xoa Pagefile khi shutdown..." -Level "INFO"

    if (-not $DryRun) {
        try {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
                -Name "ClearPageFileAtShutdown" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Log "Da bat Clear Pagefile at Shutdown" -Level "SUCCESS"
            $totalDeleted++
        } catch { $errors++ }
    }

    # ============================================================
    # 15. Xoa Recycle Bin ($Recycle.Bin)
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 15: Xoa Recycle Bin..." -Level "INFO"

    if (-not $DryRun) {
        try {
            $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }
            foreach ($drive in $drives) {
                $recyclePath = "$($drive.Root)`$Recycle.Bin"
                if (Test-Path $recyclePath) {
                    Get-ChildItem -Path $recyclePath -Recurse -Force -ErrorAction SilentlyContinue |
                        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    $totalDeleted++
                }
            }
            if (Get-Command Clear-RecycleBin -ErrorAction SilentlyContinue) {
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            }
            Write-Log "Xoa Recycle Bin thanh cong" -Level "SUCCESS"
        } catch { $errors++ }
    }

    Add-CleanStat -Category "FilesDeleted" -Count $totalDeleted
    Add-CleanStat -Category "Errors" -Count $errors

    Write-LogSeparator
    Write-Log "Hoan tat System Cache Clean. Tong: $totalDeleted, Loi: $errors" -Level "INFO"
}
