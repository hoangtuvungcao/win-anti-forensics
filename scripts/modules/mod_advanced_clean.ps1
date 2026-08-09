# ============================================================
# USB Windows History Cleaner - Module: Advanced Clean
# Xoa nang cao: Recycle Bin, Search Index, Clipboard, Wipe Space
# ============================================================

function Clear-AdvancedHistory {
    <#
    .SYNOPSIS
    Xoa nang cao cac dau vet con lai tren he thong
    #>
    param(
        [PSCustomObject[]]$Users,
        [bool]$DryRun = $false
    )

    Write-Log "XOA NANG CAO (ADVANCED CLEAN)" -Level "HEADER"

    $totalDeleted = 0
    $errors = 0

    # ============================================================
    # 1. Xoa Recycle Bin
    # ============================================================

    Write-Log "Buoc 1: Xoa Recycle Bin (Thung rac)..." -Level "INFO"

    try {
        # Xoa tat ca $Recycle.Bin tren moi drive
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }
        foreach ($drive in $drives) {
            $recyclePath = "$($drive.Root)`$Recycle.Bin"
            if (Test-Path $recyclePath) {
                try {
                    Get-ChildItem -Path $recyclePath -Recurse -Force -ErrorAction SilentlyContinue |
                        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    $totalDeleted++
                } catch { }
            }
        }

        # Dung COM object de don sach
        try {
            if (Get-Command Clear-RecycleBin -ErrorAction SilentlyContinue) {
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            }
        } catch { }

        Write-Log "Xoa Recycle Bin thanh cong" -Level "SUCCESS"
    } catch {
        Write-Log "Loi xoa Recycle Bin: $($_.Exception.Message)" -Level "WARNING"
        $errors++
    }

    # ============================================================
    # 2. Xoa Windows Search Index
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 2: Xoa Windows Search Index..." -Level "INFO"

    try {
        # Dung service Search
        Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

        $searchDataPath = "$env:ProgramData\Microsoft\Search\Data"
        if (Test-Path $searchDataPath) {
            try {
                Remove-Item -Path "$searchDataPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Xoa Search Index data" -Level "SUCCESS"
                $totalDeleted++
            } catch {
                $errors++
            }
        }

        # Xoa search database
        $searchDB = "$env:ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb"
        if (Test-Path $searchDB) {
            Remove-Item -Path $searchDB -Force -ErrorAction SilentlyContinue
            $totalDeleted++
        }

        # Khoi dong lai Search service
        Start-Service -Name "WSearch" -ErrorAction SilentlyContinue
        Write-Log "Xoa Windows Search Index thanh cong" -Level "SUCCESS"
    } catch {
        Start-Service -Name "WSearch" -ErrorAction SilentlyContinue
        Write-Log "Loi xoa Search Index: $($_.Exception.Message)" -Level "WARNING"
        $errors++
    }

    # ============================================================
    # 3. Xoa Clipboard History
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 3: Xoa Clipboard History..." -Level "INFO"

    try {
        # Xoa clipboard hien tai
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.Clipboard]::Clear()

        # Xoa Clipboard history (Win10 1809+)
        $clipHistoryPath = "$env:LOCALAPPDATA\Microsoft\Windows\Clipboard"
        if (Test-Path $clipHistoryPath) {
            Remove-Item -Path "$clipHistoryPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            $totalDeleted++
        }

        Write-Log "Xoa Clipboard History thanh cong" -Level "SUCCESS"
    } catch {
        $errors++
    }

    # ============================================================
    # 4. Xoa Notification History
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 4: Xoa Notification History..." -Level "INFO"

    foreach ($user in $Users) {
        $notifPath = "$($user.ProfilePath)\AppData\Local\Microsoft\Windows\Notifications"
        if (Test-Path $notifPath) {
            try {
                # Xoa database thong bao
                $notifDB = Get-ChildItem -Path $notifPath -Filter "wpndatabase*" -ErrorAction SilentlyContinue
                $notifDB | Remove-Item -Force -ErrorAction SilentlyContinue
                $totalDeleted += ($notifDB | Measure-Object).Count
                Write-Log "Xoa Notification DB cho $($user.Name)" -Level "SUCCESS"
            } catch {
                $errors++
            }
        }
    }

    # ============================================================
    # 5. Xoa Diagnostic Data
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 5: Xoa Diagnostic va Telemetry Data..." -Level "INFO"

    $diagPaths = @(
        "$env:ProgramData\Microsoft\Diagnosis\ETLLogs",
        "$env:ProgramData\Microsoft\Diagnosis\DownloadedSettings",
        "$env:SystemRoot\System32\SleepStudy",
        "$env:SystemRoot\System32\sru"
    )

    foreach ($diagPath in $diagPaths) {
        if (Test-Path $diagPath) {
            try {
                $items = Get-ChildItem -Path $diagPath -Recurse -ErrorAction SilentlyContinue
                $count = ($items | Measure-Object).Count
                Remove-Item -Path "$diagPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Xoa $count diagnostic items: $(Split-Path $diagPath -Leaf)" -Level "SUCCESS"
                $totalDeleted += $count
            } catch {
                $errors++
            }
        }
    }

    # ============================================================
    # 6. Xoa Windows Defender History
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 6: Xoa Windows Defender scan history..." -Level "INFO"

    $defenderPaths = @(
        "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Results",
        "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Service",
        "$env:ProgramData\Microsoft\Windows Defender\Support"
    )

    foreach ($defPath in $defenderPaths) {
        if (Test-Path $defPath) {
            try {
                Remove-Item -Path "$defPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Xoa Defender history: $(Split-Path $defPath -Leaf)" -Level "SUCCESS"
                $totalDeleted++
            } catch {
                $errors++
            }
        }
    }

    # ============================================================
    # 7. Xoa doskey (CMD history) cho session hien tai
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 7: Xoa CMD History..." -Level "INFO"

    try {
        cmd /c "doskey /reinstall" 2>$null
        Write-Log "Reset CMD command history" -Level "SUCCESS"
        $totalDeleted++
    } catch {
        $errors++
    }

    # ============================================================
    # 8. Xoa Paint, Notepad, WordPad recent
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 8: Xoa lich su ung dung Windows built-in..." -Level "INFO"

    foreach ($user in $Users) {
        $regBase = Get-UserRegistryPath -User $user
        if (-not $regBase) { continue }

        $builtinAppPaths = @(
            "$regBase\Software\Microsoft\Windows\CurrentVersion\Applets\Paint\Recent File List",
            "$regBase\Software\Microsoft\Windows\CurrentVersion\Applets\Wordpad\Recent File List",
            "$regBase\Software\Microsoft\Notepad",
            "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\CIDSizeMRU"
        )

        foreach ($appPath in $builtinAppPaths) {
            if (Test-Path $appPath) {
                try {
                    $props = Get-ItemProperty -Path $appPath -ErrorAction SilentlyContinue
                    $count = 0
                    foreach ($prop in $props.PSObject.Properties) {
                        if ($prop.Name -like "File*" -or $prop.Name -like "szDir*" -or $prop.Name -match "^\d+$") {
                            Remove-ItemProperty -Path $appPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                            $count++
                        }
                    }
                    if ($count -gt 0) {
                        Write-Log "Xoa $count entries: $(Split-Path $appPath -Leaf)" -Level "SUCCESS"
                        $totalDeleted += $count
                    }
                } catch {
                    $errors++
                }
            }
        }

        Unload-UserRegistry -User $user
    }

    # ============================================================
    # 9. Wipe Free Space (Tuy chon - rat cham)
    # ============================================================

    Write-LogSeparator
    Write-Host ""
    Write-Host "  ╔════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║  TUY CHON: Ghi de vung trong (Wipe Free   ║" -ForegroundColor Yellow
    Write-Host "  ║  Space) de chong phuc hoi du lieu.         ║" -ForegroundColor Yellow
    Write-Host "  ║  CANH BAO: Rat cham (co the mat hang gio)  ║" -ForegroundColor Yellow
    Write-Host "  ╚════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""

    $wipeChoice = Read-Host "  Ban co muon Wipe Free Space? (Y/N, mac dinh: N)"
    if ($wipeChoice -eq "Y" -or $wipeChoice -eq "y") {
        Write-Log "Bat dau Wipe Free Space (cipher /w:C:\)..." -Level "WARNING"
        Write-Log "Qua trinh nay se mat nhieu thoi gian. Khong tat may!" -Level "WARNING"

        try {
            $systemDrive = $env:SystemDrive
            Start-Process -FilePath "cipher.exe" -ArgumentList "/w:$systemDrive\" -Wait -NoNewWindow
            Write-Log "Wipe Free Space hoan tat!" -Level "SUCCESS"
        } catch {
            Write-Log "Loi Wipe Free Space: $($_.Exception.Message)" -Level "ERROR"
            $errors++
        }
    } else {
        Write-Log "Bo qua Wipe Free Space" -Level "INFO"
    }

    # Cap nhat stats
    Add-CleanStat -Category "FilesDeleted" -Count $totalDeleted
    Add-CleanStat -Category "Errors" -Count $errors

    Write-LogSeparator
    Write-Log "Hoan tat Advanced Clean. Tong: $totalDeleted, Loi: $errors" -Level "INFO"
}
