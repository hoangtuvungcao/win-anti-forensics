# ============================================================
# USB Windows History Cleaner - Logger Utility
# Ghi log chi tiet moi thao tac ra file va console
# ============================================================

# Khoi tao duong dan log
$script:LogDir = $null
$script:LogFile = $null
$script:LogInitialized = $false

function Initialize-Logger {
    param(
        [string]$BasePath
    )

    $script:LogDir = Join-Path $BasePath "logs"
    if (-not (Test-Path $script:LogDir)) {
        New-Item -ItemType Directory -Path $script:LogDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:LogFile = Join-Path $script:LogDir "cleaner_$timestamp.log"

    # Tao file log
    $header = @"
================================================================
  USB WINDOWS HISTORY CLEANER - LOG FILE
  Thoi gian bat dau: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
  May tinh: $env:COMPUTERNAME
  User hien tai: $env:USERNAME
================================================================

"@
    $header | Out-File -FilePath $script:LogFile -Encoding UTF8
    $script:LogInitialized = $true
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "HEADER", "DETAIL")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Ghi ra file
    if ($script:LogInitialized -and $script:LogFile) {
        $logEntry | Out-File -FilePath $script:LogFile -Encoding UTF8 -Append
    }

    # Hien thi console voi mau sac
    switch ($Level) {
        "INFO"    { Write-Host "  [*] $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "  [+] $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "  [!] $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "  [-] $Message" -ForegroundColor Red }
        "HEADER"  { 
            Write-Host ""
            Write-Host "  ============================================" -ForegroundColor Magenta
            Write-Host "  $Message" -ForegroundColor Magenta
            Write-Host "  ============================================" -ForegroundColor Magenta
        }
        "DETAIL"  { Write-Host "      $Message" -ForegroundColor DarkGray }
    }
}

function Write-LogSeparator {
    Write-Host ""
    Write-Host "  --------------------------------------------" -ForegroundColor DarkGray
    if ($script:LogInitialized -and $script:LogFile) {
        "--------------------------------------------" | Out-File -FilePath $script:LogFile -Encoding UTF8 -Append
    }
}

function Get-LogFilePath {
    return $script:LogFile
}

# Tracker dem so luong item da xoa
$script:CleanStats = @{
    FilesDeleted = 0
    RegistryKeysDeleted = 0
    EventLogsCleared = 0
    Errors = 0
}

function Add-CleanStat {
    param(
        [string]$Category,
        [int]$Count = 1
    )
    if ($script:CleanStats.ContainsKey($Category)) {
        $script:CleanStats[$Category] += $Count
    }
}

function Get-CleanStats {
    return $script:CleanStats
}

function Reset-CleanStats {
    $script:CleanStats = @{
        FilesDeleted = 0
        RegistryKeysDeleted = 0
        EventLogsCleared = 0
        Errors = 0
    }
}
