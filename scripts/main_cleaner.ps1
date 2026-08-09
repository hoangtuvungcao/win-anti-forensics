# ============================================================
# USB Windows History Cleaner v2.0 - Main Controller
# Nang cao: DRY_RUN mode, auto-detect, thong minh hon
# ============================================================

param(
    [switch]$DryRun,        # Che do test - chi log, khong xoa
    [switch]$AutoDeepClean, # Tu dong Deep Clean khong hoi
    [switch]$Silent         # Che do im lang (it output)
)

# Xac dinh duong dan goc cua USB
$global:USBRoot = Split-Path -Path $PSScriptRoot -Parent
$global:IsDryRun = $DryRun.IsPresent
$global:StartTime = Get-Date

# ============================================================
# Load cac module va utility
# ============================================================

$utilsPath = Join-Path $PSScriptRoot "utils"
$modulesPath = Join-Path $PSScriptRoot "modules"

# Load theo thu tu dependency
. "$utilsPath\logger.ps1"
. "$utilsPath\report.ps1"
. "$modulesPath\mod_detect_users.ps1"
. "$modulesPath\mod_event_logs.ps1"
. "$modulesPath\mod_usb_history.ps1"
. "$modulesPath\mod_file_history.ps1"
. "$modulesPath\mod_shellbags.ps1"
. "$modulesPath\mod_wifi_history.ps1"
. "$modulesPath\mod_browser_history.ps1"
. "$modulesPath\mod_app_history.ps1"
. "$modulesPath\mod_advanced_clean.ps1"
. "$modulesPath\mod_system_cache.ps1"

# ============================================================
# Kiem tra quyen Administrator
# ============================================================

function Test-AdminPrivilege {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================================
# Kiem tra he thong truoc khi chay
# ============================================================

function Test-SystemReadiness {
    <#
    .SYNOPSIS
    Kiem tra he thong truoc khi chay - phat hien van de tiem an
    #>

    $issues = @()

    # Kiem tra OS
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os) {
        $version = [System.Version]$os.Version
        if ($version.Major -lt 10) {
            $issues += "OS cu ($($os.Caption)) - mot so tinh nang co the khong hoat dong"
        }
    }

    # Kiem tra PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $issues += "PowerShell version $($PSVersionTable.PSVersion) - can 5.1+"
    }

    # Kiem tra dung luong USB de luu log
    $usbDrive = Split-Path $global:USBRoot -Qualifier
    $usbDisk = Get-PSDrive -Name ($usbDrive -replace ":") -ErrorAction SilentlyContinue
    if ($usbDisk -and $usbDisk.Free -lt 10MB) {
        $issues += "USB con it dung luong (<10MB) - co the khong luu duoc log"
    }

    # Kiem tra co phan mem bao ve nao dang chay
    $securitySoftware = @("MsMpEng", "avp", "avgnt", "avguard", "ekrn")
    foreach ($sw in $securitySoftware) {
        if (Get-Process -Name $sw -ErrorAction SilentlyContinue) {
            $issues += "Phan mem bao ve ($sw) dang chay - co the chan mot so thao tac"
        }
    }

    return $issues
}

# ============================================================
# Thu thap thong tin he thong de hien thi
# ============================================================

function Get-SystemSummary {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }

    return @{
        ComputerName = $env:COMPUTERNAME
        UserName     = $env:USERNAME
        OS           = if ($os) { $os.Caption } else { "Unknown" }
        OSBuild      = if ($os) { $os.BuildNumber } else { "Unknown" }
        IsAdmin      = Test-AdminPrivilege
        USBPath      = $global:USBRoot
        DriveCount   = $drives.Count
        DryRun       = $global:IsDryRun
    }
}

# ============================================================
# Hien thi Banner
# ============================================================

function Show-Banner {
    Clear-Host

    $dryRunBanner = ""
    if ($global:IsDryRun) {
        $dryRunBanner = @"

    ╔══════════════════════════════════════════════════════════════╗
    ║  ⚠  CHE DO TEST (DRY-RUN) - KHONG XOA THAT                  ║
    ║     Chi mo phong va log nhung gi se xoa                      ║
    ╚══════════════════════════════════════════════════════════════╝
"@
    }

    $banner = @"

    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║     ██╗   ██╗███████╗██████╗      ██████╗██╗     ███╗   ██╗ ║
    ║     ██║   ██║██╔════╝██╔══██╗    ██╔════╝██║     ████╗  ██║ ║
    ║     ██║   ██║███████╗██████╔╝    ██║     ██║     ██╔██╗ ██║ ║
    ║     ██║   ██║╚════██║██╔══██╗    ██║     ██║     ██║╚██╗██║ ║
    ║     ╚██████╔╝███████║██████╔╝    ╚██████╗███████╗██║ ╚████║ ║
    ║      ╚═════╝ ╚══════╝╚═════╝     ╚═════╝╚══════╝╚═╝  ╚═══╝ ║
    ║                                                              ║
    ║         USB WINDOWS HISTORY CLEANER v2.0                     ║
    ║         Xoa sach lich su hoat dong may tinh                  ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
$dryRunBanner
"@
    Write-Host $banner -ForegroundColor $(if ($global:IsDryRun) {"Yellow"} else {"Cyan"})

    # System info
    $info = Get-SystemSummary
    Write-Host "  May tinh    : $($info.ComputerName)" -ForegroundColor DarkGray
    Write-Host "  User        : $($info.UserName)" -ForegroundColor DarkGray
    Write-Host "  OS          : $($info.OS) (Build $($info.OSBuild))" -ForegroundColor DarkGray
    Write-Host "  Quyen Admin : $(if ($info.IsAdmin) { 'CO' } else { 'KHONG' })" -ForegroundColor $(if ($info.IsAdmin) {"Green"} else {"Red"})
    Write-Host "  USB Path    : $($info.USBPath)" -ForegroundColor DarkGray

    if ($global:IsDryRun) {
        Write-Host "  Mode        : DRY-RUN (TEST)" -ForegroundColor Yellow
    }
    Write-Host ""

    # Kiem tra system readiness
    $issues = Test-SystemReadiness
    if ($issues.Count -gt 0) {
        Write-Host "  ⚠ Canh bao he thong:" -ForegroundColor Yellow
        foreach ($issue in $issues) {
            Write-Host "    - $issue" -ForegroundColor Yellow
        }
        Write-Host ""
    }
}

# ============================================================
# Quet va hien thi thong tin truoc khi xoa
# ============================================================

function Show-PreCleanSummary {
    param(
        [PSCustomObject[]]$Users
    )

    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host "     THONG TIN TRUOC KHI XOA" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($user in $Users) {
        Write-Host "  User: $($user.Name)" -ForegroundColor White
        $profilePath = $user.ProfilePath

        # Dem browsers
        $browsers = Find-InstalledBrowsers -UserProfilePath $profilePath
        if ($browsers.Count -gt 0) {
            Write-Host "    Trinh duyet: $($browsers.Count) - $($browsers.Name -join ', ')" -ForegroundColor DarkGray
        }

        # Dem recent files
        $recentPath = "$profilePath\AppData\Roaming\Microsoft\Windows\Recent"
        if (Test-Path $recentPath) {
            $recentCount = (Get-ChildItem -Path $recentPath -File -ErrorAction SilentlyContinue | Measure-Object).Count
            Write-Host "    Recent files: $recentCount" -ForegroundColor DarkGray
        }

        # Dem temp files
        $tempPath = "$profilePath\AppData\Local\Temp"
        if (Test-Path $tempPath) {
            $tempCount = (Get-ChildItem -Path $tempPath -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
            Write-Host "    Temp files: $tempCount" -ForegroundColor DarkGray
        }

        Write-Host ""
    }

    # System-wide info
    $prefetchCount = (Get-ChildItem -Path "$env:SystemRoot\Prefetch" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $eventLogCount = (wevtutil el 2>$null | Measure-Object).Count

    Write-Host "  He thong:" -ForegroundColor White
    Write-Host "    Prefetch files: $prefetchCount" -ForegroundColor DarkGray
    Write-Host "    Event logs: $eventLogCount" -ForegroundColor DarkGray

    # WiFi profiles
    $wifiOutput = netsh wlan show profiles 2>$null
    if ($wifiOutput) {
        $wifiCount = ($wifiOutput | Select-String "All User Profile|T.{1,5}t c.{1,3}" | Measure-Object).Count
        Write-Host "    WiFi profiles: $wifiCount" -ForegroundColor DarkGray
    }

    Write-Host ""
}

# ============================================================
# Menu chon che do xoa
# ============================================================

function Show-CleanModeMenu {
    Write-Host "  ============================================" -ForegroundColor Yellow
    Write-Host "          CHON CHE DO XOA" -ForegroundColor Yellow
    Write-Host "  ============================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] " -NoNewline -ForegroundColor White
    Write-Host "QUICK CLEAN  " -NoNewline -ForegroundColor Green
    Write-Host "- Xoa nhanh (Logs, Files, Temp)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [2] " -NoNewline -ForegroundColor White
    Write-Host "DEEP CLEAN   " -NoNewline -ForegroundColor Red
    Write-Host "- Xoa TRIET DE tat ca (9 modules)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [3] " -NoNewline -ForegroundColor White
    Write-Host "CUSTOM       " -NoNewline -ForegroundColor Cyan
    Write-Host "- Tu chon module" -ForegroundColor DarkGray
    Write-Host ""

    if (-not $global:IsDryRun) {
        Write-Host "  [T] " -NoNewline -ForegroundColor White
        Write-Host "TEST MODE    " -NoNewline -ForegroundColor Yellow
        Write-Host "- Chay thu (DRY-RUN), khong xoa that" -ForegroundColor DarkGray
        Write-Host ""
    }

    Write-Host "  [0] Thoat" -ForegroundColor DarkGray
    Write-Host ""

    return Read-Host "  Chon che do"
}

# ============================================================
# Menu chon module (Custom mode)
# ============================================================

function Show-CustomModuleMenu {
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host "        CHON MODULE CAN XOA" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Event Logs         - Nhat ky su kien Windows" -ForegroundColor White
    Write-Host "  [2] USB/Device History  - Lich su thiet bi USB/ngoai vi" -ForegroundColor White
    Write-Host "  [3] File History        - Recent, Prefetch, Temp, MRU" -ForegroundColor White
    Write-Host "  [4] Shell Bags          - Lich su duyet thu muc" -ForegroundColor White
    Write-Host "  [5] WiFi History        - WiFi profiles, WLAN logs" -ForegroundColor White
    Write-Host "  [6] Browser History     - TAT CA trinh duyet (24+ loai)" -ForegroundColor White
    Write-Host "  [7] App History         - UserAssist, Timeline, RDP, BAM" -ForegroundColor White
    Write-Host "  [8] Advanced Clean      - Clipboard, Defender, Diagnostic" -ForegroundColor White
    Write-Host "  [9] System Cache        - DNS, Font, WinUpdate, VSS, Cred" -ForegroundColor White
    Write-Host ""
    Write-Host "  Nhap so cac module, cach nhau boi dau phay" -ForegroundColor DarkGray
    Write-Host "  Vi du: 1,2,3 hoac 1,3,5,6,7" -ForegroundColor DarkGray
    Write-Host ""

    $choices = Read-Host "  Chon module"
    return $choices -split "," | ForEach-Object { $_.Trim() }
}

# ============================================================
# Xac nhan truoc khi xoa
# ============================================================

function Confirm-CleanAction {
    param(
        [string]$Mode,
        [string[]]$ModuleNames,
        [PSCustomObject[]]$Users
    )

    Write-Host ""

    if ($global:IsDryRun) {
        Write-Host "  ╔════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "  ║  CHE DO TEST - Chi mo phong, khong xoa     ║" -ForegroundColor Yellow
        Write-Host "  ╚════════════════════════════════════════════╝" -ForegroundColor Yellow
    } else {
        Write-Host "  ╔════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "  ║           XAC NHAN TRUOC KHI XOA           ║" -ForegroundColor Red
        Write-Host "  ╚════════════════════════════════════════════╝" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  Che do    : $Mode $(if($global:IsDryRun){'(DRY-RUN)'})" -ForegroundColor White
    Write-Host "  User      : $($Users.Name -join ', ')" -ForegroundColor White
    Write-Host "  Module    :" -ForegroundColor White

    foreach ($mod in $ModuleNames) {
        Write-Host "              - $mod" -ForegroundColor Yellow
    }

    Write-Host ""

    if ($global:IsDryRun) {
        Write-Host "  Nhan Enter de bat dau TEST..." -ForegroundColor Yellow
        Read-Host
        return $true
    }

    Write-Host "  CANH BAO: Thao tac nay KHONG THE HOAN TAC!" -ForegroundColor Red
    Write-Host ""

    $confirm = Read-Host "  Nhap 'XOA' de xac nhan (hoac bat ky phim nao de huy)"
    return ($confirm -eq "XOA")
}

# ============================================================
# Ham chay module - truyen DryRun vao moi module
# ============================================================

function Invoke-CleanModule {
    param(
        [string]$ModuleNumber,
        [PSCustomObject[]]$Users,
        [bool]$DryRun = $false
    )

    switch ($ModuleNumber) {
        "1" { Clear-AllEventLogs -DryRun $DryRun; return "Event Logs" }
        "2" { Clear-USBHistory -DryRun $DryRun; return "USB/Device History" }
        "3" { Clear-FileHistory -Users $Users -DryRun $DryRun; return "File History" }
        "4" { Clear-ShellBags -Users $Users -DryRun $DryRun; return "Shell Bags" }
        "5" { Clear-WiFiHistory -DryRun $DryRun; return "WiFi History" }
        "6" { Clear-BrowserHistory -Users $Users -DryRun $DryRun; return "Browser History (All)" }
        "7" { Clear-AppHistory -Users $Users -DryRun $DryRun; return "App History & Timeline" }
        "8" { Clear-AdvancedHistory -Users $Users -DryRun $DryRun; return "Advanced Clean" }
        "9" { Clear-SystemCache -Users $Users -DryRun $DryRun; return "System Cache & Deep Clean" }
        default { Write-Log "Module khong hop le: $ModuleNumber" -Level "WARNING"; return $null }
    }
}

# ============================================================
# Xac minh sau khi xoa
# ============================================================

function Test-PostCleanVerification {
    <#
    .SYNOPSIS
    Kiem tra xem da xoa sach chua
    #>

    Write-Log "KIEM TRA SAU KHI XOA" -Level "HEADER"

    $checks = @()

    # Kiem tra Event Logs
    $remainingLogs = 0
    try {
        $logNames = wevtutil el 2>$null
        foreach ($logName in $logNames) {
            $info = wevtutil gli "$logName" 2>$null | Select-String "numberOfLogRecords:"
            if ($info -match "numberOfLogRecords:\s*(\d+)") {
                $count = [int]$Matches[1]
                if ($count -gt 0) { $remainingLogs++ }
            }
        }
    } catch { }
    $checks += @{ Name = "Event Logs"; Status = $(if ($remainingLogs -eq 0) {"SACH"} else {"Con $remainingLogs logs co du lieu"}); Clean = ($remainingLogs -eq 0) }

    # Kiem tra Prefetch
    $prefetchCount = (Get-ChildItem -Path "$env:SystemRoot\Prefetch" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $checks += @{ Name = "Prefetch"; Status = $(if ($prefetchCount -eq 0) {"SACH"} else {"Con $prefetchCount files"}); Clean = ($prefetchCount -eq 0) }

    # Kiem tra Recent
    $recentCount = (Get-ChildItem -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Recent" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $checks += @{ Name = "Recent Files"; Status = $(if ($recentCount -eq 0) {"SACH"} else {"Con $recentCount files"}); Clean = ($recentCount -eq 0) }

    # Kiem tra USBSTOR
    $usbstorCount = 0
    $usbstorPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"
    if (Test-Path $usbstorPath) {
        $usbstorCount = (Get-ChildItem -Path $usbstorPath -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    }
    $checks += @{ Name = "USBSTOR Registry"; Status = $(if ($usbstorCount -le 1) {"SACH"} else {"Con $usbstorCount entries"}); Clean = ($usbstorCount -le 1) }

    # Kiem tra WiFi
    $wifiCount = 0
    $wifiOutput = netsh wlan show profiles 2>$null
    if ($wifiOutput) {
        $wifiCount = ($wifiOutput | Select-String "All User Profile|T.{1,5}t c.{1,3}" | Measure-Object).Count
    }
    $checks += @{ Name = "WiFi Profiles"; Status = $(if ($wifiCount -eq 0) {"SACH"} else {"Con $wifiCount profiles"}); Clean = ($wifiCount -eq 0) }

    # Hien thi ket qua
    Write-Host ""
    Write-Host "  ╔════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║         KET QUA KIEM TRA SAU XOA            ║" -ForegroundColor Cyan
    Write-Host "  ╚════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    $cleanCount = 0
    foreach ($check in $checks) {
        $icon = if ($check.Clean) { "[✓]"; $cleanCount++ } else { "[!]" }
        $color = if ($check.Clean) { "Green" } else { "Yellow" }
        Write-Host "  $icon $($check.Name.PadRight(20)) : $($check.Status)" -ForegroundColor $color
    }

    $score = [math]::Round(($cleanCount / $checks.Count) * 100)
    Write-Host ""
    Write-Host "  Diem sach: $score% ($cleanCount/$($checks.Count) muc)" -ForegroundColor $(if ($score -ge 80) {"Green"} elseif ($score -ge 50) {"Yellow"} else {"Red"})

    if ($score -lt 100) {
        Write-Host ""
        Write-Host "  Luu y: Mot so muc khong the xoa 100% khi Windows dang chay." -ForegroundColor DarkGray
        Write-Host "  De xoa triet de, hay boot tu WinPE va chay offline_cleaner." -ForegroundColor DarkGray
    }

    Write-Host ""
}

# ============================================================
# MAIN - Bat dau chuong trinh
# ============================================================

# Kiem tra quyen Admin
if (-not (Test-AdminPrivilege)) {
    Write-Host ""
    Write-Host "  LOI: Can quyen Administrator de chay tool nay!" -ForegroundColor Red
    Write-Host "  Hay click phai LAUNCHER.bat va chon 'Run as administrator'" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Nhan Enter de thoat"
    exit 1
}

# Khoi tao Logger
Initialize-Logger -BasePath $global:USBRoot

# Hien thi banner
Show-Banner

# Ghi log bat dau
$modeText = if ($global:IsDryRun) { "DRY-RUN" } else { "PRODUCTION" }
Write-Log "Bat dau USB Windows History Cleaner v2.0 [$modeText]" -Level "INFO"
Write-Log "May tinh: $env:COMPUTERNAME | User: $env:USERNAME" -Level "INFO"

# ============================================================
# Buoc 1: Chon User
# ============================================================

$selectedUsers = Select-Users
if (-not $selectedUsers) {
    Write-Log "Khong co user nao duoc chon. Thoat." -Level "WARNING"
    Read-Host "  Nhan Enter de thoat"
    exit 0
}

# Hien thi thong tin scan
Show-PreCleanSummary -Users $selectedUsers

# ============================================================
# Buoc 2: Chon che do xoa
# ============================================================

if ($AutoDeepClean.IsPresent) {
    $cleanMode = "2"
} else {
    $cleanMode = Show-CleanModeMenu
}

$modulesToRun = @()
$moduleNames = @()
$cleanModeText = ""

switch ($cleanMode) {
    "1" {
        # Quick Clean
        $modulesToRun = @("1", "3", "8")
        $moduleNames = @("Event Logs", "File History", "Advanced Clean")
        $cleanModeText = "QUICK CLEAN"
    }
    "2" {
        # Deep Clean - tat ca 9 module
        $modulesToRun = @("1", "2", "3", "4", "5", "6", "7", "8", "9")
        $moduleNames = @(
            "Event Logs", "USB/Device History", "File History",
            "Shell Bags", "WiFi History", "Browser History (24+ loai)",
            "App History & Timeline", "Advanced Clean", "System Cache & Deep Clean"
        )
        $cleanModeText = "DEEP CLEAN"
    }
    "3" {
        # Custom
        $customModules = Show-CustomModuleMenu
        $modulesToRun = $customModules
        $moduleMap = @{
            "1" = "Event Logs"; "2" = "USB/Device History"; "3" = "File History"
            "4" = "Shell Bags"; "5" = "WiFi History"; "6" = "Browser History (24+ loai)"
            "7" = "App History & Timeline"; "8" = "Advanced Clean"; "9" = "System Cache & Deep Clean"
        }
        $moduleNames = $modulesToRun | ForEach-Object { $moduleMap[$_] } | Where-Object { $_ }
        $cleanModeText = "CUSTOM"
    }
    { $_ -eq "T" -or $_ -eq "t" } {
        # Switch sang DRY-RUN mode
        $global:IsDryRun = $true
        Write-Host ""
        Write-Host "  Da chuyen sang che do TEST (DRY-RUN)" -ForegroundColor Yellow
        Write-Host "  Chay lai de chon module..." -ForegroundColor Yellow
        Write-Host ""

        # Chon lai che do
        $modulesToRun = @("1", "2", "3", "4", "5", "6", "7", "8", "9")
        $moduleNames = @(
            "Event Logs", "USB/Device History", "File History",
            "Shell Bags", "WiFi History", "Browser History (24+ loai)",
            "App History & Timeline", "Advanced Clean", "System Cache & Deep Clean"
        )
        $cleanModeText = "TEST (DRY-RUN) - ALL MODULES"
    }
    "0" {
        Write-Log "Nguoi dung chon thoat." -Level "INFO"
        exit 0
    }
    default {
        Write-Log "Lua chon khong hop le!" -Level "ERROR"
        Read-Host "  Nhan Enter de thoat"
        exit 1
    }
}

# ============================================================
# Buoc 3: Xac nhan
# ============================================================

$confirmed = Confirm-CleanAction -Mode $cleanModeText -ModuleNames $moduleNames -Users $selectedUsers

if (-not $confirmed) {
    Write-Log "Nguoi dung huy thao tac." -Level "WARNING"
    Read-Host "  Nhan Enter de thoat"
    exit 0
}

# ============================================================
# Buoc 4: Chay cac module
# ============================================================

Write-Host ""
$headerText = if ($global:IsDryRun) { "BAT DAU TEST (DRY-RUN)..." } else { "BAT DAU XOA LICH SU..." }
Write-Log $headerText -Level "HEADER"
Write-Host ""

Reset-CleanStats

$completedModules = @()

foreach ($moduleNum in $modulesToRun) {
    $moduleName = Invoke-CleanModule -ModuleNumber $moduleNum -Users $selectedUsers -DryRun $global:IsDryRun
    if ($moduleName) {
        $completedModules += $moduleName
    }
    Write-Host ""
}

# ============================================================
# Buoc 5: Xac minh sau khi xoa
# ============================================================

if (-not $global:IsDryRun) {
    Test-PostCleanVerification
}

# ============================================================
# Buoc 6: Tao bao cao
# ============================================================

$stats = Get-CleanStats

$reportPath = Generate-CleanReport `
    -BasePath $global:USBRoot `
    -Stats $stats `
    -ModulesRun $completedModules `
    -SelectedUsers ($selectedUsers | ForEach-Object { $_.Name }) `
    -CleanMode "$cleanModeText $(if($global:IsDryRun){'[DRY-RUN]'})" `
    -StartTime $global:StartTime

Show-CleanSummary -Stats $stats -ReportPath $reportPath

$logPath = Get-LogFilePath
Write-Host "  File log chi tiet: $logPath" -ForegroundColor DarkGray
Write-Host ""

# ============================================================
# Xoa PowerShell history cua session hien tai
# ============================================================

if (-not $global:IsDryRun) {
    try {
        Clear-History -ErrorAction SilentlyContinue
    } catch { }
}

$endMessage = if ($global:IsDryRun) {
    "TEST HOAN TAT! Xem log de kiem tra."
} else {
    "HOAN TAT! Co the rut USB an toan."
}

Write-Host "  ============================================" -ForegroundColor Green
Write-Host "       $endMessage" -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor Green
Write-Host ""

if ($global:IsDryRun) {
    Write-Host "  De xoa that, chay lai va chon DEEP CLEAN." -ForegroundColor Yellow
    Write-Host ""
}

Read-Host "  Nhan Enter de thoat"
