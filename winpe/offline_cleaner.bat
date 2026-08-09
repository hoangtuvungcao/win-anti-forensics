@echo off
REM ============================================================
REM USB Windows History Cleaner - Offline Cleaner (WinPE)
REM Chay trong moi truong WinPE de xoa triet de
REM ============================================================

title USB History Cleaner - Offline Mode (WinPE)

echo.
echo   ============================================
echo     USB WINDOWS HISTORY CLEANER - OFFLINE MODE
echo     Chay trong moi truong WinPE
echo   ============================================
echo.

REM Tim o dia chua Windows
echo   Dang tim o dia chua Windows...
echo.

set "WIN_DRIVE="

for %%d in (C D E F G H I) do (
    if exist "%%d:\Windows\System32\config" (
        echo   Tim thay Windows tren o %%d:
        set "WIN_DRIVE=%%d:"
        goto :found_windows
    )
)

echo   LOI: Khong tim thay o dia chua Windows!
echo   Vui long kiem tra lai.
pause
exit /b 1

:found_windows
echo.
echo   Su dung o dia: %WIN_DRIVE%
echo.

REM Kiem tra PowerShell trong WinPE
where powershell >nul 2>&1
if %errorlevel% equ 0 (
    echo   Tim thay PowerShell - su dung script nang cao...
    set "SCRIPT_DIR=%~dp0"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%offline_cleaner.ps1" -WinDrive %WIN_DRIVE%
    goto :done
)

REM Fallback: Dung CMD de xoa neu khong co PowerShell
echo   Khong co PowerShell - su dung CMD de xoa...
echo.
echo   CANH BAO: Thao tac nay se xoa TOAN BO lich su!
echo.
set /p "CONFIRM=  Nhap 'XOA' de xac nhan: "
if /i not "%CONFIRM%"=="XOA" (
    echo   Da huy thao tac.
    pause
    exit /b 0
)

echo.
echo   [1/6] Xoa Event Logs...
if exist "%WIN_DRIVE%\Windows\System32\winevt\Logs" (
    del /f /q "%WIN_DRIVE%\Windows\System32\winevt\Logs\*.evtx" 2>nul
    echo   OK - Event logs da xoa
) else (
    echo   Bo qua - Khong tim thay
)

echo   [2/6] Xoa Prefetch...
if exist "%WIN_DRIVE%\Windows\Prefetch" (
    del /f /q "%WIN_DRIVE%\Windows\Prefetch\*" 2>nul
    echo   OK - Prefetch da xoa
)

echo   [3/6] Xoa WLAN log file...
if exist "%WIN_DRIVE%\Windows\System32\winevt\Logs\Microsoft-Windows-WLAN-AutoConfig%%4Operational.evtx" (
    del /f /q "%WIN_DRIVE%\Windows\System32\winevt\Logs\Microsoft-Windows-WLAN-AutoConfig%%4Operational.evtx" 2>nul
    echo   OK - WLAN log da xoa
)

echo   [4/6] Xoa Temp files...
if exist "%WIN_DRIVE%\Windows\Temp" (
    del /f /q /s "%WIN_DRIVE%\Windows\Temp\*" 2>nul
    echo   OK - System temp da xoa
)

echo   [5/6] Xoa Setup logs...
if exist "%WIN_DRIVE%\Windows\INF\setupapi.dev.log" (
    del /f /q "%WIN_DRIVE%\Windows\INF\setupapi.dev.log" 2>nul
    echo   OK - Setup logs da xoa
)

echo   [6/6] Xoa Recent files cho cac user...
for /d %%u in ("%WIN_DRIVE%\Users\*") do (
    if exist "%%u\AppData\Roaming\Microsoft\Windows\Recent" (
        del /f /q "%%u\AppData\Roaming\Microsoft\Windows\Recent\*" 2>nul
        del /f /q "%%u\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations\*" 2>nul
        del /f /q "%%u\AppData\Roaming\Microsoft\Windows\Recent\CustomDestinations\*" 2>nul
        echo   OK - Recent files cho %%~nxu
    )
    if exist "%%u\AppData\Local\Temp" (
        del /f /q /s "%%u\AppData\Local\Temp\*" 2>nul
    )
)

:done
echo.
echo   ============================================
echo     HOAN TAT! Khoi dong lai may tinh.
echo   ============================================
echo.
pause
exit /b 0
