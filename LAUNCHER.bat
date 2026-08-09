@echo off
REM ============================================================
REM USB Windows History Cleaner v2.0 - LAUNCHER
REM Click dup file nay de bat dau
REM Ho tro: Auto-run, DRY-RUN test mode
REM ============================================================

title USB Windows History Cleaner v2.0

REM Kiem tra tham so dong lenh
set "EXTRA_ARGS="
if /i "%1"=="--dryrun" set "EXTRA_ARGS=-DryRun"
if /i "%1"=="--test" set "EXTRA_ARGS=-DryRun"
if /i "%1"=="--auto" set "EXTRA_ARGS=-AutoDeepClean"
if /i "%1"=="--auto-test" set "EXTRA_ARGS=-DryRun -AutoDeepClean"

REM Kiem tra quyen Admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   ============================================
    echo     USB WINDOWS HISTORY CLEANER v2.0
    echo   ============================================
    echo.
    echo   Dang yeu cau quyen Administrator...
    echo   Vui long nhan "Yes/Co" tren hop thoai UAC.
    echo.

    REM Tu dong yeu cau UAC elevation voi tham so
    if defined EXTRA_ARGS (
        powershell -Command "Start-Process '%~f0' -ArgumentList '%1' -Verb RunAs"
    ) else (
        powershell -Command "Start-Process '%~f0' -Verb RunAs"
    )
    exit /b
)

REM Da co quyen Admin
echo.
echo   ============================================
echo     USB WINDOWS HISTORY CLEANER v2.0
echo     Dang khoi dong...
if defined EXTRA_ARGS echo     Mode: %EXTRA_ARGS%
echo   ============================================
echo.

REM Xac dinh thu muc chua script
set "SCRIPT_DIR=%~dp0scripts"

REM Kiem tra PowerShell
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo   LOI: Khong tim thay PowerShell!
    echo   Tool nay can PowerShell 5.1+ de hoat dong.
    pause
    exit /b 1
)

REM Kiem tra file script chinh
if not exist "%SCRIPT_DIR%\main_cleaner.ps1" (
    echo   LOI: Khong tim thay file main_cleaner.ps1!
    echo   Cau truc can co:
    echo     USB_DRIVE\
    echo       LAUNCHER.bat
    echo       scripts\main_cleaner.ps1
    pause
    exit /b 1
)

REM Chay PowerShell voi Execution Policy bypass
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\main_cleaner.ps1" %EXTRA_ARGS%

if %errorlevel% neq 0 (
    echo.
    echo   Co loi xay ra. Kiem tra logs\
    echo.
)

exit /b 0
