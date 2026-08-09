# ============================================================
# USB Windows History Cleaner - Module: Event Logs
# Xoa toan bo nhat ky su kien Windows
# ============================================================

function Clear-AllEventLogs {
    param(
        [bool]$DryRun = $false
    )

    Write-Log "XOA NHAT KY SU KIEN (EVENT LOGS)" -Level "HEADER"

    $totalCleared = 0
    $errors = 0

    # Lay danh sach tat ca event logs
    try {
        $logNames = wevtutil el 2>$null
        if (-not $logNames) {
            Write-Log "Khong the lay danh sach event logs" -Level "ERROR"
            Add-CleanStat -Category "Errors"
            return
        }

        $totalLogs = ($logNames | Measure-Object).Count
        Write-Log "Tim thay $totalLogs event logs can xoa..." -Level "INFO"

        if ($DryRun) {
            Write-Log "[DRY-RUN] Se xoa $totalLogs event logs" -Level "DETAIL"
            $totalCleared = $totalLogs
        } else {
            $count = 0
            foreach ($logName in $logNames) {
                $count++
                if ($count % 50 -eq 0) {
                    Write-Host "`r  [*] Dang xoa... $count/$totalLogs logs" -NoNewline -ForegroundColor Cyan
                }
                try {
                    wevtutil cl "$logName" 2>$null
                    $totalCleared++
                } catch {
                    $errors++
                }
            }
            Write-Host "`r" -NoNewline
        }

        Write-Log "Da xoa $totalCleared/$totalLogs event logs" -Level "SUCCESS"

    } catch {
        Write-Log "Loi khi xoa event logs: $($_.Exception.Message)" -Level "ERROR"
        $errors++
    }

    Write-LogSeparator

    # Xoa Windows Error Reporting
    $werPaths = @(
        "$env:ProgramData\Microsoft\Windows\WER\ReportArchive",
        "$env:ProgramData\Microsoft\Windows\WER\ReportQueue",
        "$env:LOCALAPPDATA\Microsoft\Windows\WER"
    )

    foreach ($werPath in $werPaths) {
        if (Test-Path $werPath) {
            try {
                $items = Get-ChildItem -Path $werPath -Recurse -ErrorAction SilentlyContinue
                $itemCount = ($items | Measure-Object).Count
                if (-not $DryRun) {
                    Remove-Item -Path "$werPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                }
                Write-Log "$(if($DryRun){'[DRY-RUN] '})Xoa WER: $werPath ($itemCount items)" -Level "SUCCESS"
                $totalCleared += $itemCount
            } catch {
                $errors++
            }
        }
    }

    # Xoa Crash Dumps
    $dumpPaths = @(
        "$env:LOCALAPPDATA\CrashDumps",
        "$env:SystemRoot\Minidump",
        "$env:SystemRoot\MEMORY.DMP"
    )

    foreach ($dumpPath in $dumpPaths) {
        if (Test-Path $dumpPath) {
            try {
                if (-not $DryRun) {
                    if ((Get-Item $dumpPath).PSIsContainer) {
                        $items = Get-ChildItem -Path $dumpPath -ErrorAction SilentlyContinue
                        $itemCount = ($items | Measure-Object).Count
                        Remove-Item -Path "$dumpPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                    } else {
                        Remove-Item -Path $dumpPath -Force -ErrorAction SilentlyContinue
                        $itemCount = 1
                    }
                    $totalCleared += $itemCount
                }
                Write-Log "Xoa Crash Dumps: $dumpPath" -Level "SUCCESS"
            } catch { $errors++ }
        }
    }

    # Xoa Setup logs
    $setupLogs = @(
        "$env:SystemRoot\setupapi.log",
        "$env:SystemRoot\INF\setupapi.dev.log",
        "$env:SystemRoot\INF\setupapi.app.log",
        "$env:SystemRoot\Panther\setupact.log",
        "$env:SystemRoot\Panther\setuperr.log"
    )

    foreach ($logPath in $setupLogs) {
        if (Test-Path $logPath) {
            try {
                if (-not $DryRun) {
                    Remove-Item -Path $logPath -Force -ErrorAction SilentlyContinue
                }
                Write-Log "$(if($DryRun){'[DRY-RUN] '})Xoa: $(Split-Path $logPath -Leaf)" -Level "SUCCESS"
                $totalCleared++
            } catch { $errors++ }
        }
    }

    Add-CleanStat -Category "EventLogsCleared" -Count $totalCleared
    Add-CleanStat -Category "Errors" -Count $errors

    Write-LogSeparator
    Write-Log "Hoan tat xoa Event Logs. Tong: $totalCleared, Loi: $errors" -Level "INFO"
}
