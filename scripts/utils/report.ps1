# ============================================================
# USB Windows History Cleaner - Report Utility
# Tao bao cao tong ket sau khi xoa
# ============================================================

function Generate-CleanReport {
    param(
        [string]$BasePath,
        [hashtable]$Stats,
        [string[]]$ModulesRun,
        [string[]]$SelectedUsers,
        [string]$CleanMode,
        [datetime]$StartTime
    )

    $endTime = Get-Date
    $duration = $endTime - $StartTime

    $reportDir = Join-Path $BasePath "logs"
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = Join-Path $reportDir "report_$timestamp.txt"

    $report = @"
================================================================
     BAO CAO XOA LICH SU - USB WINDOWS HISTORY CLEANER
================================================================

  Thoi gian bat dau : $($StartTime.ToString("yyyy-MM-dd HH:mm:ss"))
  Thoi gian ket thuc: $($endTime.ToString("yyyy-MM-dd HH:mm:ss"))
  Thoi gian thuc hien: $($duration.ToString("hh\:mm\:ss"))

  May tinh           : $env:COMPUTERNAME
  OS                 : $((Get-CimInstance Win32_OperatingSystem).Caption)
  Che do xoa         : $CleanMode

----------------------------------------------------------------
  USER DA XOA LICH SU
----------------------------------------------------------------

"@

    foreach ($user in $SelectedUsers) {
        $report += "  - $user`n"
    }

    $report += @"

----------------------------------------------------------------
  MODULE DA CHAY
----------------------------------------------------------------

"@

    foreach ($mod in $ModulesRun) {
        $report += "  [x] $mod`n"
    }

    $report += @"

----------------------------------------------------------------
  THONG KE
----------------------------------------------------------------

  File da xoa          : $($Stats.FilesDeleted)
  Registry key da xoa  : $($Stats.RegistryKeysDeleted)
  Event logs da xoa    : $($Stats.EventLogsCleared)
  Loi gap phai         : $($Stats.Errors)

================================================================
  KET QUA: $(if ($Stats.Errors -eq 0) { "THANH CONG - KHONG CO LOI" } else { "HOAN TAT VOI $($Stats.Errors) LOI" })
================================================================
"@

    $report | Out-File -FilePath $reportFile -Encoding UTF8
    return $reportFile
}

function Show-CleanSummary {
    param(
        [hashtable]$Stats,
        [string]$ReportPath
    )

    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Green
    Write-Host "           TONG KET XOA LICH SU" -ForegroundColor Green
    Write-Host "  ============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  File da xoa         : $($Stats.FilesDeleted)" -ForegroundColor White
    Write-Host "  Registry key da xoa : $($Stats.RegistryKeysDeleted)" -ForegroundColor White
    Write-Host "  Event logs da xoa   : $($Stats.EventLogsCleared)" -ForegroundColor White

    if ($Stats.Errors -gt 0) {
        Write-Host "  Loi gap phai        : $($Stats.Errors)" -ForegroundColor Red
    } else {
        Write-Host "  Loi gap phai        : 0" -ForegroundColor Green
    }

    Write-Host ""
    if ($ReportPath) {
        Write-Host "  Bao cao chi tiet: $ReportPath" -ForegroundColor DarkGray
    }
    Write-Host ""
}
