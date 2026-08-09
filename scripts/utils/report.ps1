# ============================================================
# USB Windows History Cleaner - Report Utility
# Tao bao cao TXT & HTML tong ket sau khi xoa
# Compatible with PS 2.0, 3.0, 4.0, 5.1, 7.x
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
    $durText = "{0:D2}:{1:D2}:{2:D2}" -f $duration.Hours, $duration.Minutes, $duration.Seconds

    $reportDir = Join-Path $BasePath "logs"
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFileTxt = Join-Path $reportDir "report_$timestamp.txt"
    $reportFileHtml = Join-Path $reportDir "report_$timestamp.html"

    $osCaption = "Windows"
    try {
        $osObj = Get-WmiObject Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($osObj) { $osCaption = $osObj.Caption }
    } catch { }

    $resultText = "THANH CONG - KHONG CO LOI"
    $statusClass = "success"
    if ($Stats.Errors -gt 0) {
        $resultText = "HOAN TAT VOI " + $Stats.Errors + " LOI"
        $statusClass = "warning"
    }

    # ============================================================
    # 1. TAO FILE TXT (Windows Notepad compatible)
    # ============================================================

    $lines = @(
        "================================================================"
        "     BAO CAO XOA LICH SU - USB WINDOWS HISTORY CLEANER v2.0"
        "================================================================"
        ""
        "  [+] THONG TIN PHIEN CHAY"
        "  --------------------------------------------------------------"
        "  Thoi gian bat dau  : $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        "  Thoi gian ket thuc : $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        "  Thoi gian thuc hien: $durText"
        ""
        "  May tinh           : $env:COMPUTERNAME"
        "  He dieu hanh       : $osCaption"
        "  Che do xoa         : $CleanMode"
        ""
        "  [+] TAP NGUOI DUNG DA XU LY"
        "  --------------------------------------------------------------"
    )

    foreach ($user in $SelectedUsers) {
        $lines += "  - $user"
    }

    $lines += ""
    $lines += "  [+] DANH SACH MODULE DA THUC HIEN"
    $lines += "  --------------------------------------------------------------"
    foreach ($mod in $ModulesRun) {
        $lines += "  [x] $mod"
    }

    $lines += ""
    $lines += "  [+] THONG KE CHI TIET"
    $lines += "  --------------------------------------------------------------"
    $lines += "  File da xoa          : $($Stats.FilesDeleted)"
    $lines += "  Registry key da xoa  : $($Stats.RegistryKeysDeleted)"
    $lines += "  Event logs da xoa    : $($Stats.EventLogsCleared)"
    $lines += "  Loi gap phai         : $($Stats.Errors)"
    $lines += ""
    $lines += "================================================================"
    $lines += "  KET QUA TONG THE: $resultText"
    $lines += "================================================================"
    $lines += ""

    try {
        $lines | Out-File -FilePath $reportFileTxt -Encoding utf8 -Force
    } catch {
        # Fallback for old PS versions
        [System.IO.File]::WriteAllLines($reportFileTxt, [string[]]$lines)
    }

    # ============================================================
    # 2. TAO FILE HTML PREVIEWS (Mo tren Browser)
    # ============================================================

    $userItemsHtml = ($SelectedUsers | ForEach-Object { "<li>$_</li>" }) -join "`n"
    $modItemsHtml = ($ModulesRun | ForEach-Object { "<li class='mod-item'><span class='check'>✔</span> $_</li>" }) -join "`n"

    $errColorStyle = "#10b981"
    if ($Stats.Errors -gt 0) {
        $errColorStyle = "#ef4444"
    }

    $htmlContent = @"
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Bao Cao Xoa Lich Su - USB Cleaner v2.0</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; background: #1e293b; border-radius: 12px; padding: 30px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; }
        .header { text-align: center; border-bottom: 2px solid #334155; padding-bottom: 20px; margin-bottom: 25px; }
        .header h1 { color: #38bdf8; margin: 0 0 10px 0; font-size: 24px; }
        .badge { display: inline-block; padding: 6px 16px; border-radius: 20px; font-weight: bold; font-size: 13px; text-transform: uppercase; }
        .badge-success { background: #059669; color: #fff; }
        .badge-warning { background: #d97706; color: #fff; }
        .stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 25px; }
        .card { background: #0f172a; padding: 15px; border-radius: 8px; text-align: center; border: 1px solid #334155; }
        .card .num { font-size: 26px; font-weight: bold; color: #38bdf8; margin-top: 5px; }
        .card .label { font-size: 12px; color: #94a3b8; }
        .section { margin-bottom: 25px; background: #0f172a; padding: 18px; border-radius: 8px; border: 1px solid #334155; }
        .section-title { font-size: 16px; color: #38bdf8; margin: 0 0 12px 0; border-bottom: 1px dashed #334155; padding-bottom: 8px; }
        table { width: 100%; border-collapse: collapse; }
        td { padding: 8px 0; font-size: 14px; border-bottom: 1px solid #1e293b; }
        td.label { color: #94a3b8; width: 35%; }
        ul { margin: 0; padding-left: 20px; }
        li { margin-bottom: 6px; font-size: 14px; }
        .mod-item { list-style: none; margin-left: -20px; }
        .check { color: #10b981; font-weight: bold; margin-right: 8px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>USB WINDOWS HISTORY CLEANER v2.0</h1>
            <span class="badge badge-$statusClass">$resultText</span>
        </div>

        <div class="stats-grid">
            <div class="card"><div class="label">File Da Xoa</div><div class="num">$($Stats.FilesDeleted)</div></div>
            <div class="card"><div class="label">Registry Keys</div><div class="num">$($Stats.RegistryKeysDeleted)</div></div>
            <div class="card"><div class="label">Event Logs</div><div class="num">$($Stats.EventLogsCleared)</div></div>
            <div class="card"><div class="label">Loi Gap Phai</div><div class="num" style="color: $errColorStyle">$($Stats.Errors)</div></div>
        </div>

        <div class="section">
            <div class="section-title">THONG TIN PHIEN CHAY</div>
            <table>
                <tr><td class="label">Thoi gian bat dau</td><td>$($StartTime.ToString("yyyy-MM-dd HH:mm:ss"))</td></tr>
                <tr><td class="label">Thoi gian ket thuc</td><td>$($endTime.ToString("yyyy-MM-dd HH:mm:ss"))</td></tr>
                <tr><td class="label">Thoi gian thuc hien</td><td>$durText</td></tr>
                <tr><td class="label">May tinh</td><td>$env:COMPUTERNAME</td></tr>
                <tr><td class="label">He dieu hanh</td><td>$osCaption</td></tr>
                <tr><td class="label">Che do xoa</td><td>$CleanMode</td></tr>
            </table>
        </div>

        <div class="section">
            <div class="section-title">USERS DA XU LY</div>
            <ul>$userItemsHtml</ul>
        </div>

        <div class="section">
            <div class="section-title">MODULES DA THUC HIEN</div>
            <div>$modItemsHtml</div>
        </div>
    </div>
</body>
</html>
"@

    try {
        $htmlContent | Out-File -FilePath $reportFileHtml -Encoding utf8 -Force
    } catch {
        [System.IO.File]::WriteAllText($reportFileHtml, $htmlContent)
    }

    return $reportFileTxt
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
        Write-Host "  Bao cao TXT : $ReportPath" -ForegroundColor White
        $htmlPath = $ReportPath -replace "\.txt$", ".html"
        if (Test-Path $htmlPath) {
            Write-Host "  Bao cao HTML: $htmlPath" -ForegroundColor Cyan
        }
    }
    Write-Host ""
}
