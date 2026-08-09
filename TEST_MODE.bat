@echo off
REM ============================================================
REM USB Windows History Cleaner - TEST MODE
REM Chay DRY-RUN de kiem tra truoc khi xoa that
REM Chi log nhung gi se xoa, KHONG xoa bat ky thu gi
REM ============================================================

title USB History Cleaner - TEST MODE (DRY-RUN)

echo.
echo   ============================================
echo     CHE DO TEST (DRY-RUN)
echo     Chi mo phong - KHONG XOA bat ky thu gi
echo   ============================================
echo.

call "%~dp0LAUNCHER.bat" --test
