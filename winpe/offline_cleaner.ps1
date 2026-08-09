# ============================================================
# USB Windows History Cleaner - Offline Cleaner (WinPE)
# Script PowerShell chay trong moi truong WinPE
# Xoa triet de tat ca lich su khi Windows khong chay
# Compatible with PS 3.0, 4.0, 5.1, 7.x
# ============================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$WinDrive
)

$ConfirmPreference = 'None'
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
# Banner
# ============================================================

function Show-OfflineBanner {
    Clear-Host
    Write-Host ""
    Write-Host "  ==================================================" -ForegroundColor Cyan
    Write-Host "     USB HISTORY CLEANER - OFFLINE MODE (WinPE)     " -ForegroundColor Cyan
    Write-Host "     Xoa triet de khi Windows khong hoat dong       " -ForegroundColor Cyan
    Write-Host "  ==================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Windows Drive: $WinDrive" -ForegroundColor White
    Write-Host ""
}

# ============================================================
# Tim cac user profiles
# ============================================================

function Get-OfflineUsers {
    $usersPath = "$WinDrive\Users"
    $systemProfiles = @("Default", "Default User", "Public", "All Users")

    $users = @()
    if (Test-Path $usersPath) {
        $profiles = Get-ChildItem -Path $usersPath -Directory |
            Where-Object { $_.Name -notin $systemProfiles }

        foreach ($profile in $profiles) {
            if (Test-Path "$($profile.FullName)\NTUSER.DAT") {
                $users += $profile
            }
        }
    }
    return $users
}

# ============================================================
# Main Offline Cleaning
# ============================================================

Show-OfflineBanner

# Tim users
$users = Get-OfflineUsers
Write-Host "  Tim thay $($users.Count) user profiles:" -ForegroundColor White
foreach ($u in $users) {
    Write-Host "    - $($u.Name)" -ForegroundColor Yellow
}
Write-Host ""

# Xac nhan
$confirm = Read-Host "  Nhap 'XOA' de xoa TOAN BO lich su (hoac bat ky phim nao de huy)"
if ($confirm -ne "XOA") {
    Write-Host "  Da huy." -ForegroundColor Yellow
    Read-Host "  Nhan Enter de thoat"
    exit 0
}

$totalDeleted = 0
$errors = 0

# ============================================================
# 1. Xoa TAT CA Event Log files (.evtx)
# ============================================================

Write-Host ""
Write-Host "  [1/10] Xoa Event Log files..." -ForegroundColor Cyan

$evtxPath = "$WinDrive\Windows\System32\winevt\Logs"
if (Test-Path $evtxPath) {
    $evtxFiles = Get-ChildItem -Path $evtxPath -Filter "*.evtx"
    $count = ($evtxFiles | Measure-Object).Count
    $evtxFiles | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "    Xoa $count event log files" -ForegroundColor Green
    $totalDeleted += $count
}

# ============================================================
# 2. Xoa Prefetch
# ============================================================

Write-Host "  [2/10] Xoa Prefetch..." -ForegroundColor Cyan

$prefetchPath = "$WinDrive\Windows\Prefetch"
if (Test-Path $prefetchPath) {
    $items = Get-ChildItem -Path $prefetchPath -File
    $count = ($items | Measure-Object).Count
    Remove-Item -Path "$prefetchPath\*" -Force -ErrorAction SilentlyContinue
    Write-Host "    Xoa $count prefetch files" -ForegroundColor Green
    $totalDeleted += $count
}

# ============================================================
# 3. Xoa Setup logs
# ============================================================

Write-Host "  [3/10] Xoa Setup va INF logs..." -ForegroundColor Cyan

$setupLogs = @(
    "$WinDrive\Windows\INF\setupapi.dev.log",
    "$WinDrive\Windows\INF\setupapi.app.log",
    "$WinDrive\Windows\setupapi.log",
    "$WinDrive\Windows\Panther\setupact.log",
    "$WinDrive\Windows\Panther\setuperr.log"
)

foreach ($log in $setupLogs) {
    if (Test-Path $log) {
        Remove-Item -Path $log -Force -ErrorAction SilentlyContinue
        Write-Host "    Xoa: $(Split-Path $log -Leaf)" -ForegroundColor Green
        $totalDeleted++
    }
}

# ============================================================
# 4. Xoa System Temp
# ============================================================

Write-Host "  [4/10] Xoa System Temp..." -ForegroundColor Cyan

$systemTemp = "$WinDrive\Windows\Temp"
if (Test-Path $systemTemp) {
    $items = Get-ChildItem -Path $systemTemp -Recurse
    $count = ($items | Measure-Object).Count
    Remove-Item -Path "$systemTemp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "    Xoa $count temp items" -ForegroundColor Green
    $totalDeleted += $count
}

# ============================================================
# 5. Xoa Crash Dumps
# ============================================================

Write-Host "  [5/10] Xoa Crash Dumps..." -ForegroundColor Cyan

$dumpPaths = @(
    "$WinDrive\Windows\Minidump",
    "$WinDrive\Windows\MEMORY.DMP"
)

foreach ($dump in $dumpPaths) {
    if (Test-Path $dump) {
        if ((Get-Item $dump).PSIsContainer) {
            Remove-Item -Path "$dump\*" -Force -ErrorAction SilentlyContinue
        } else {
            Remove-Item -Path $dump -Force -ErrorAction SilentlyContinue
        }
        Write-Host "    Xoa: $(Split-Path $dump -Leaf)" -ForegroundColor Green
        $totalDeleted++
    }
}

# ============================================================
# 6. Xoa WLAN config files
# ============================================================

Write-Host "  [6/10] Xoa WLAN config files..." -ForegroundColor Cyan

$wlansvcPath = "$WinDrive\ProgramData\Microsoft\Wlansvc\Profiles\Interfaces"
if (Test-Path $wlansvcPath) {
    $interfaces = Get-ChildItem -Path $wlansvcPath -Directory
    foreach ($iface in $interfaces) {
        $xmlFiles = Get-ChildItem -Path $iface.FullName -Filter "*.xml"
        $count = ($xmlFiles | Measure-Object).Count
        $xmlFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        $totalDeleted += $count
    }
    Write-Host "    Xoa WLAN profiles" -ForegroundColor Green
}

# ============================================================
# 7. Xoa WER (Windows Error Reporting)
# ============================================================

Write-Host "  [7/10] Xoa Windows Error Reports..." -ForegroundColor Cyan

$werPaths = @(
    "$WinDrive\ProgramData\Microsoft\Windows\WER\ReportArchive",
    "$WinDrive\ProgramData\Microsoft\Windows\WER\ReportQueue"
)

foreach ($werPath in $werPaths) {
    if (Test-Path $werPath) {
        Remove-Item -Path "$werPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        $totalDeleted++
    }
}
Write-Host "    Xoa WER reports" -ForegroundColor Green

# ============================================================
# 8. Xoa Diagnostic va Telemetry
# ============================================================

Write-Host "  [8/10] Xoa Diagnostic data..." -ForegroundColor Cyan

$diagPaths = @(
    "$WinDrive\ProgramData\Microsoft\Diagnosis\ETLLogs",
    "$WinDrive\Windows\System32\SleepStudy"
)

foreach ($diagPath in $diagPaths) {
    if (Test-Path $diagPath) {
        Remove-Item -Path "$diagPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        $totalDeleted++
    }
}
Write-Host "    Xoa Diagnostic data" -ForegroundColor Green

# ============================================================
# 9. Xoa theo tung User
# ============================================================

Write-Host "  [9/10] Xoa lich su tung user..." -ForegroundColor Cyan

foreach ($user in $users) {
    Write-Host "    User: $($user.Name)" -ForegroundColor Yellow
    $profilePath = $user.FullName

    # Recent Files
    $recentPaths = @(
        "$profilePath\AppData\Roaming\Microsoft\Windows\Recent",
        "$profilePath\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations",
        "$profilePath\AppData\Roaming\Microsoft\Windows\Recent\CustomDestinations"
    )

    foreach ($recentPath in $recentPaths) {
        if (Test-Path $recentPath) {
            $items = Get-ChildItem -Path $recentPath -File
            $count = ($items | Measure-Object).Count
            Remove-Item -Path "$recentPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            $totalDeleted += $count
        }
    }

    # User Temp
    $userTemp = "$profilePath\AppData\Local\Temp"
    if (Test-Path $userTemp) {
        Remove-Item -Path "$userTemp\*" -Recurse -Force -ErrorAction SilentlyContinue
        $totalDeleted++
    }

    # Thumbnail Cache
    $thumbPath = "$profilePath\AppData\Local\Microsoft\Windows\Explorer"
    if (Test-Path $thumbPath) {
        Get-ChildItem -Path $thumbPath -Filter "thumbcache_*" | Remove-Item -Force -ErrorAction SilentlyContinue
        $totalDeleted++
    }

    # Timeline
    $timelinePath = "$profilePath\AppData\Local\ConnectedDevicesPlatform"
    if (Test-Path $timelinePath) {
        Remove-Item -Path "$timelinePath\*" -Recurse -Force -ErrorAction SilentlyContinue
        $totalDeleted++
    }

    # PowerShell History
    $psHistory = "$profilePath\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    if (Test-Path $psHistory) {
        Remove-Item -Path $psHistory -Force -ErrorAction SilentlyContinue
        $totalDeleted++
    }

    # Browser data - Chrome
    $chromeData = "$profilePath\AppData\Local\Google\Chrome\User Data"
    if (Test-Path $chromeData) {
        $chromeProfiles = @("Default") + (Get-ChildItem -Path $chromeData -Directory -Filter "Profile *" | ForEach-Object { $_.Name })
        foreach ($cp in $chromeProfiles) {
            $cpPath = "$chromeData\$cp"
            if (Test-Path $cpPath) {
                @("History", "Cookies", "Web Data", "Visited Links", "Top Sites",
                  "Shortcuts", "Favicons", "Last Session", "Last Tabs", "Current Session", "Current Tabs") | ForEach-Object {
                    $f = "$cpPath\$_"
                    if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue; $totalDeleted++ }
                }
                @("Cache", "Code Cache", "GPUCache") | ForEach-Object {
                    $d = "$cpPath\$_"
                    if (Test-Path $d) { Remove-Item "$d\*" -Recurse -Force -ErrorAction SilentlyContinue; $totalDeleted++ }
                }
            }
        }
    }

    # Edge
    $edgeData = "$profilePath\AppData\Local\Microsoft\Edge\User Data"
    if (Test-Path $edgeData) {
        $edgeProfiles = @("Default") + (Get-ChildItem -Path $edgeData -Directory -Filter "Profile *" | ForEach-Object { $_.Name })
        foreach ($ep in $edgeProfiles) {
            $epPath = "$edgeData\$ep"
            if (Test-Path $epPath) {
                @("History", "Cookies", "Web Data", "Visited Links", "Top Sites",
                  "Shortcuts", "Favicons", "Last Session", "Last Tabs", "Current Session", "Current Tabs") | ForEach-Object {
                    $f = "$epPath\$_"
                    if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue; $totalDeleted++ }
                }
                @("Cache", "Code Cache", "GPUCache") | ForEach-Object {
                    $d = "$epPath\$_"
                    if (Test-Path $d) { Remove-Item "$d\*" -Recurse -Force -ErrorAction SilentlyContinue; $totalDeleted++ }
                }
            }
        }
    }

    # Firefox
    $ffData = "$profilePath\AppData\Roaming\Mozilla\Firefox\Profiles"
    if (Test-Path $ffData) {
        $ffProfiles = Get-ChildItem -Path $ffData -Directory -ErrorAction SilentlyContinue
        foreach ($ffp in $ffProfiles) {
            @("places.sqlite", "cookies.sqlite", "formhistory.sqlite", "downloads.sqlite") | ForEach-Object {
                $f = "$($ffp.FullName)\$_"
                if (Test-Path $f) { Remove-Item $f -Force -ErrorAction SilentlyContinue; $totalDeleted++ }
            }
        }
    }

    # IE Cache
    $iePaths = @(
        "$profilePath\AppData\Local\Microsoft\Windows\INetCache",
        "$profilePath\AppData\Local\Microsoft\Windows\INetCookies",
        "$profilePath\AppData\Local\Microsoft\Windows\History"
    )
    foreach ($iePath in $iePaths) {
        if (Test-Path $iePath) {
            Remove-Item -Path "$iePath\*" -Recurse -Force -ErrorAction SilentlyContinue
            $totalDeleted++
        }
    }

    # Notifications
    $notifPath = "$profilePath\AppData\Local\Microsoft\Windows\Notifications"
    if (Test-Path $notifPath) {
        Get-ChildItem -Path $notifPath -Filter "wpndatabase*" | Remove-Item -Force -ErrorAction SilentlyContinue
        $totalDeleted++
    }

    Write-Host "      OK" -ForegroundColor Green
}

# ============================================================
# 10. Xoa Registry offline (Load hive)
# ============================================================

Write-Host "  [10/10] Xoa Registry offline..." -ForegroundColor Cyan

# Load SYSTEM hive
$systemHivePath = "$WinDrive\Windows\System32\config\SYSTEM"
if (Test-Path $systemHivePath) {
    try {
        reg load "HKLM\OFFLINE_SYSTEM" "$systemHivePath" 2>$null

        # Xoa USBSTOR
        $usbstorPath = "HKLM\OFFLINE_SYSTEM\ControlSet001\Enum\USBSTOR"
        reg query "$usbstorPath" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $subkeys = reg query "$usbstorPath" 2>$null | Where-Object { $_ -match "HKEY_LOCAL_MACHINE" }
            foreach ($key in $subkeys) {
                $innerKeys = reg query "$key" 2>$null | Where-Object { $_ -match "HKEY_LOCAL_MACHINE" }
                foreach ($inner in $innerKeys) {
                    reg delete "$inner" /f 2>$null
                    $totalDeleted++
                }
            }
            Write-Host "    Xoa USBSTOR entries" -ForegroundColor Green
        }

        # Xoa USB Enum
        $usbEnumPath = "HKLM\OFFLINE_SYSTEM\ControlSet001\Enum\USB"
        reg query "$usbEnumPath" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $subkeys = reg query "$usbEnumPath" 2>$null | Where-Object { $_ -match "HKEY_LOCAL_MACHINE" }
            foreach ($key in $subkeys) {
                $innerKeys = reg query "$key" 2>$null | Where-Object { $_ -match "HKEY_LOCAL_MACHINE" }
                foreach ($inner in $innerKeys) {
                    reg delete "$inner" /f 2>$null
                    $totalDeleted++
                }
            }
            Write-Host "    Xoa USB Enum entries" -ForegroundColor Green
        }

        # Xoa BAM
        $bamPath = "HKLM\OFFLINE_SYSTEM\ControlSet001\Services\bam\State\UserSettings"
        reg query "$bamPath" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $subkeys = reg query "$bamPath" 2>$null | Where-Object { $_ -match "HKEY_LOCAL_MACHINE" }
            foreach ($key in $subkeys) {
                reg delete "$key" /f 2>$null
                $totalDeleted++
            }
            Write-Host "    Xoa BAM entries" -ForegroundColor Green
        }

        [gc]::Collect()
        Start-Sleep -Seconds 1
        reg unload "HKLM\OFFLINE_SYSTEM" 2>$null
    } catch {
        Write-Host "    Loi xu ly SYSTEM hive" -ForegroundColor Red
        $errors++
        try { reg unload "HKLM\OFFLINE_SYSTEM" 2>$null } catch {}
    }
}

# Load SOFTWARE hive
$softwareHivePath = "$WinDrive\Windows\System32\config\SOFTWARE"
if (Test-Path $softwareHivePath) {
    try {
        reg load "HKLM\OFFLINE_SOFTWARE" "$softwareHivePath" 2>$null

        # Xoa Network List Profiles
        $netListPath = "HKLM\OFFLINE_SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles"
        reg query "$netListPath" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $subkeys = reg query "$netListPath" 2>$null | Where-Object { $_ -match "HKEY_LOCAL_MACHINE" }
            foreach ($key in $subkeys) {
                reg delete "$key" /f 2>$null
                $totalDeleted++
            }
            Write-Host "    Xoa Network List Profiles" -ForegroundColor Green
        }

        # Xoa Network Signatures
        $netSigPath = "HKLM\OFFLINE_SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures"
        reg query "$netSigPath" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $subkeys = reg query "$netSigPath" 2>$null | Where-Object { $_ -match "HKEY_LOCAL_MACHINE" }
            foreach ($key in $subkeys) {
                $innerKeys = reg query "$key" 2>$null | Where-Object { $_ -match "HKEY_LOCAL_MACHINE" }
                foreach ($inner in $innerKeys) {
                    reg delete "$inner" /f 2>$null
                    $totalDeleted++
                }
            }
            Write-Host "    Xoa Network Signatures" -ForegroundColor Green
        }

        # Xoa Portable Devices
        $portDevPath = "HKLM\OFFLINE_SOFTWARE\Microsoft\Windows Portable Devices\Devices"
        reg query "$portDevPath" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $subkeys = reg query "$portDevPath" 2>$null | Where-Object { $_ -match "HKEY_LOCAL_MACHINE" }
            foreach ($key in $subkeys) {
                reg delete "$key" /f 2>$null
                $totalDeleted++
            }
            Write-Host "    Xoa Portable Devices" -ForegroundColor Green
        }

        [gc]::Collect()
        Start-Sleep -Seconds 1
        reg unload "HKLM\OFFLINE_SOFTWARE" 2>$null
    } catch {
        Write-Host "    Loi xu ly SOFTWARE hive" -ForegroundColor Red
        $errors++
        try { reg unload "HKLM\OFFLINE_SOFTWARE" 2>$null } catch {}
    }
}

# Load tung NTUSER.DAT cho moi user
foreach ($user in $users) {
    $ntUserPath = "$($user.FullName)\NTUSER.DAT"
    if (Test-Path $ntUserPath) {
        $hiveName = "OFFLINE_$($user.Name)"
        try {
            reg load "HKU\$hiveName" "$ntUserPath" 2>$null

            # Xoa UserAssist
            $uaPath = "HKU\$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
            reg query "$uaPath" 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $guids = reg query "$uaPath" 2>$null | Where-Object { $_ -match "HKU" }
                foreach ($guid in $guids) {
                    reg delete "$guid\Count" /f 2>$null
                    $totalDeleted++
                }
            }

            # Xoa RecentDocs
            reg delete "HKU\$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" /f 2>$null
            $totalDeleted++

            # Xoa RunMRU
            reg delete "HKU\$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /f 2>$null
            $totalDeleted++

            # Xoa TypedPaths
            reg delete "HKU\$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" /f 2>$null
            $totalDeleted++

            # Xoa WordWheelQuery
            reg delete "HKU\$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery" /f 2>$null
            $totalDeleted++

            # Xoa Shell Bags
            reg delete "HKU\$hiveName\Software\Microsoft\Windows\Shell\BagMRU" /f 2>$null
            reg delete "HKU\$hiveName\Software\Microsoft\Windows\Shell\Bags" /f 2>$null
            $totalDeleted += 2

            # Xoa ComDlg32 MRU
            reg delete "HKU\$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU" /f 2>$null
            reg delete "HKU\$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU" /f 2>$null
            $totalDeleted += 2

            # Xoa RDP History
            reg delete "HKU\$hiveName\Software\Microsoft\Terminal Server Client\Default" /f 2>$null
            reg delete "HKU\$hiveName\Software\Microsoft\Terminal Server Client\Servers" /f 2>$null
            $totalDeleted += 2

            # Xoa AppCompat
            reg delete "HKU\$hiveName\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store" /f 2>$null
            $totalDeleted++

            Write-Host "    Xoa registry cho user: $($user.Name)" -ForegroundColor Green

            [gc]::Collect()
            Start-Sleep -Seconds 1
            reg unload "HKU\$hiveName" 2>$null
        } catch {
            Write-Host "    Loi xu ly user: $($user.Name)" -ForegroundColor Red
            $errors++
            try { reg unload "HKU\$hiveName" 2>$null } catch {}
        }
    }
}

# ============================================================
# Tong ket
# ============================================================

$errColor = "White"
if ($errors -gt 0) {
    $errColor = "Red"
}

Write-Host ""
Write-Host "  ==================================================" -ForegroundColor Green
Write-Host "              HOAN TAT XOA OFFLINE!                 " -ForegroundColor Green
Write-Host "  ==================================================" -ForegroundColor Green
Write-Host "    Tong so items da xoa: $($totalDeleted.ToString().PadLeft(6))" -ForegroundColor White
Write-Host "    Loi gap phai        : $($errors.ToString().PadLeft(6))" -ForegroundColor $errColor
Write-Host "  ==================================================" -ForegroundColor Green
Write-Host "    Hay khoi dong lai may tinh de ap dung." -ForegroundColor Yellow
Write-Host "  ==================================================" -ForegroundColor Green
Write-Host ""

Read-Host "  Nhan Enter de thoat"
