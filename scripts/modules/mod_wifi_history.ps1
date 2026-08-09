# ============================================================
# USB Windows History Cleaner - Module: WiFi History
# Xoa lich su ket noi WiFi, network profiles
# ============================================================

function Clear-WiFiHistory {
    <#
    .SYNOPSIS
    Xoa toan bo lich su WiFi: profiles, event logs, va registry
    Canh bao: Se mat tat ca mat khau WiFi da luu
    #>
    param(
        [bool]$DryRun = $false
    )

    Write-Log "XOA LICH SU WI-FI VA MANG" -Level "HEADER"

    $totalDeleted = 0
    $errors = 0

    # ============================================================
    # Canh bao truoc khi xoa
    # ============================================================

    Write-Host "  +--------------------------------------------+" -ForegroundColor Red
    Write-Host "  |  CANH BAO: XOA WIFI SE MAT TAT CA MAT      |" -ForegroundColor Red
    Write-Host "  |  KHAU WIFI DA LUU! Ban se phai nhap lai    |" -ForegroundColor Red
    Write-Host "  |  mat khau WiFi sau khi xoa.                |" -ForegroundColor Red
    Write-Host "  +--------------------------------------------+" -ForegroundColor Red
    Write-Host ""

    # Backup WiFi profiles truoc khi xoa
    $backupChoice = Read-Host "  Ban co muon BACKUP mat khau WiFi truoc khong? (Y/N)"
    if ($backupChoice -eq "Y" -or $backupChoice -eq "y") {
        Export-WiFiProfiles
    }

    $confirm = Read-Host "  Xac nhan xoa lich su WiFi? (Y/N)"
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-Log "Nguoi dung huy xoa WiFi history" -Level "WARNING"
        return
    }

    # ============================================================
    # 1. Xoa WiFi Profiles
    # ============================================================

    Write-Log "Buoc 1: Xoa WiFi Profiles..." -Level "INFO"

    try {
        # Liet ke profiles truoc
        $profiles = netsh wlan show profiles 2>$null
        $profileNames = ($profiles | Select-String "All User Profile\s+:\s+(.+)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() })

        if (-not $profileNames) {
            # Thu voi tieng Viet
            $profileNames = ($profiles | Select-String "T.{1,5}t c.{1,3} h.{1,10} ng.{1,5}i d.{1,5}ng\s+:\s+(.+)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() })
        }

        if ($profileNames) {
            $count = ($profileNames | Measure-Object).Count
            Write-Log "Tim thay $count WiFi profiles" -Level "INFO"

            foreach ($name in $profileNames) {
                try {
                    netsh wlan delete profile name="$name" 2>$null | Out-Null
                    Write-Log "Xoa WiFi profile: $name" -Level "SUCCESS"
                    $totalDeleted++
                } catch {
                    $errors++
                }
            }
        } else {
            Write-Log "Khong tim thay WiFi profile nao" -Level "INFO"
        }
    } catch {
        Write-Log "Loi khi xoa WiFi profiles: $($_.Exception.Message)" -Level "ERROR"
        $errors++
    }

    # ============================================================
    # 2. Xoa WLAN Event Log
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 2: Xoa WLAN Event Logs..." -Level "INFO"

    $wlanLogs = @(
        "Microsoft-Windows-WLAN-AutoConfig/Operational",
        "Microsoft-Windows-NetworkProfile/Operational",
        "Microsoft-Windows-Dhcp-Client/Admin",
        "Microsoft-Windows-DHCPv6-Client/Admin"
    )

    foreach ($logName in $wlanLogs) {
        try {
            wevtutil cl "$logName" 2>$null
            Write-Log "Xoa WLAN log: $logName" -Level "SUCCESS"
            $totalDeleted++
        } catch {
            $errors++
        }
    }

    # ============================================================
    # 3. Xoa Network List Registry
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 3: Xoa Network List Registry..." -Level "INFO"

    $networkRegPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\Managed",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\Unmanaged",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Nla\Cache"
    )

    foreach ($path in $networkRegPaths) {
        if (Test-Path $path) {
            try {
                $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
                $count = ($items | Measure-Object).Count
                $items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Xoa $count entries: $(Split-Path $path -Leaf)" -Level "SUCCESS"
                $totalDeleted += $count
            } catch {
                $errors++
            }
        }
    }

    # ============================================================
    # 4. Xoa WLAN Interface Profiles (file system)
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 4: Xoa WLAN Interface config files..." -Level "INFO"

    $wlansvcPath = "$env:ProgramData\Microsoft\Wlansvc\Profiles\Interfaces"
    if (Test-Path $wlansvcPath) {
        try {
            $interfaces = Get-ChildItem -Path $wlansvcPath -Directory -ErrorAction SilentlyContinue
            foreach ($iface in $interfaces) {
                $xmlFiles = Get-ChildItem -Path $iface.FullName -Filter "*.xml" -ErrorAction SilentlyContinue
                $count = ($xmlFiles | Measure-Object).Count
                $xmlFiles | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-Log "Xoa $count WiFi config files: $($iface.Name.Substring(0, 8))..." -Level "SUCCESS"
                $totalDeleted += $count
            }
        } catch {
            Write-Log "Loi xoa WLAN config: $($_.Exception.Message)" -Level "WARNING"
            $errors++
        }
    }

    # ============================================================
    # 5. Xoa file WLAN log (co the bi lock)
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 5: Thu xoa WLAN log file..." -Level "INFO"

    $wlanLogFile = "$env:SystemRoot\System32\winevt\Logs\Microsoft-Windows-WLAN-AutoConfig%4Operational.evtx"
    if (Test-Path $wlanLogFile) {
        try {
            # Dung service de unlock file
            Stop-Service -Name "Wlansvc" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Remove-Item -Path $wlanLogFile -Force -ErrorAction Stop
            Start-Service -Name "Wlansvc" -ErrorAction SilentlyContinue
            Write-Log "Xoa WLAN log file thanh cong" -Level "SUCCESS"
            $totalDeleted++
        } catch {
            Start-Service -Name "Wlansvc" -ErrorAction SilentlyContinue
            Write-Log "Khong the xoa WLAN log file (file bi lock - can WinPE)" -Level "WARNING"
            Write-Log "De xoa triet de, hay boot tu WinPE va chay offline_cleaner" -Level "WARNING"
            $errors++
        }
    }

    # Cap nhat stats
    Add-CleanStat -Category "RegistryKeysDeleted" -Count $totalDeleted
    Add-CleanStat -Category "Errors" -Count $errors

    Write-LogSeparator
    Write-Log "Hoan tat xoa WiFi History. Tong: $totalDeleted, Loi: $errors" -Level "INFO"
}

function Export-WiFiProfiles {
    <#
    .SYNOPSIS
    Backup tat ca WiFi profiles (bao gom mat khau) ra USB
    #>

    $scriptRoot = Split-Path -Path $PSScriptRoot -Parent
    $backupDir = Join-Path (Split-Path $scriptRoot -Parent) "wifi_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    try {
        netsh wlan export profile key=clear folder="$backupDir" 2>$null | Out-Null
        $exported = Get-ChildItem -Path $backupDir -Filter "*.xml" -ErrorAction SilentlyContinue
        $count = ($exported | Measure-Object).Count
        Write-Log "Da backup $count WiFi profiles vao: $backupDir" -Level "SUCCESS"
        Write-Host "  Luu y: File backup chua MAT KHAU WiFi, hay bao mat!" -ForegroundColor Yellow
    } catch {
        Write-Log "Loi khi backup WiFi profiles: $($_.Exception.Message)" -Level "ERROR"
    }
}
