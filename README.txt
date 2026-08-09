================================================================
     USB WINDOWS HISTORY CLEANER v1.0
     Xoa lich su hoat dong may tinh Windows
================================================================

MO TA:
  Tool xoa triet de cac dau vet hoat dong tren may tinh 
  Windows ma KHONG can cai lai hay Reset Windows.
  Chay truc tiep tu USB, khong can cai dat.

YEU CAU HE THONG:
  - Windows 10 / Windows 11 (64-bit)
  - PowerShell 5.1+ (co san tren Win10/11)
  - Quyen Administrator
  - USB co it nhat 64MB dung luong trong

================================================================
HUONG DAN SU DUNG
================================================================

CACH 1: CHAY TRONG WINDOWS (PORTABLE MODE)
-------------------------------------------

  1. Cam USB vao may tinh can xoa lich su
  2. Mo USB trong File Explorer
  3. Click dup (Double-click) vao file LAUNCHER.bat
  4. Khi hop thoai UAC hien len, nhan "Yes" / "Co"
  5. Chon user can xoa lich su
     - Neu chi co 1 user: tu dong chon
     - Neu nhieu user: chon so tuong ung hoac 'A' cho tat ca
  6. Chon che do xoa:
     [1] QUICK CLEAN - Xoa nhanh (Event Logs + File History)
     [2] DEEP CLEAN  - Xoa triet de TAT CA lich su
     [3] CUSTOM      - Tu chon module can xoa
  7. Xac nhan bang cach nhap "XOA"
  8. Doi tool chay xong
  9. Xem bao cao trong thu muc logs/

CACH 2: CHAY OFFLINE (WINPE MODE)  
-------------------------------------------
  ** Can USB boot WinPE **

  1. Boot may tinh tu USB WinPE
  2. Mo File Explorer, tim o USB co chua tool
  3. Vao thu muc winpe\
  4. Chay offline_cleaner.bat
  5. Tool se tu tim o dia chua Windows
  6. Nhap "XOA" de xac nhan
  7. Khoi dong lai may tinh khi hoan tat

  Luu y: Mode nay xoa duoc cac file bi lock khi 
  Windows dang chay (VD: WLAN log file)

================================================================
CAC MODULE XOA
================================================================

  1. EVENT LOGS
     - Xoa tat ca Windows Event Logs
     - Xoa Windows Error Reports
     - Xoa Crash Dumps
     - Xoa Setup logs

  2. USB/DEVICE HISTORY
     - Xoa USBSTOR Registry
     - Xoa USB Enum Registry
     - Xoa MountedDevices
     - Xoa Portable Devices
     - Xoa Device Classes
     - Xoa setupapi.dev.log
     * Bao ve USB dang chay tool

  3. FILE HISTORY
     - Xoa Prefetch files
     - Xoa Recent files (+ Jump Lists)
     - Xoa Temp files (System + User)
     - Xoa Thumbnail/Icon Cache
     - Xoa Registry: RecentDocs, OpenSaveMRU, RunMRU, 
       TypedPaths, WordWheelQuery

  4. SHELL BAGS
     - Xoa BagMRU, Bags (lich su duyet thu muc)
     - Xoa Menu Order Cache
     - Xoa StreamMRU, Streams

  5. WIFI HISTORY
     - Xoa tat ca WiFi profiles (netsh)
     - Xoa WLAN Event Logs
     - Xoa Network List Registry
     - Xoa WLAN config files
     * Co tuy chon BACKUP mat khau WiFi truoc khi xoa

  6. BROWSER HISTORY
     - Google Chrome: History, Cache, Cookies, Sessions
     - Microsoft Edge: History, Cache, Cookies, Sessions
     - Mozilla Firefox: places.sqlite, cookies, cache
     - Internet Explorer: INetCache, INetCookies, History
     * KHONG xoa Bookmarks va mat khau da luu

  7. APP HISTORY & TIMELINE
     - Xoa BAM/DAM (Background Activity Monitor)
     - Xoa UserAssist (theo doi ung dung)
     - Xoa Compatibility Assistant
     - Xoa MUI Cache
     - Xoa Windows Timeline
     - Xoa PowerShell command history
     - Xoa RDP History (Remote Desktop)
     - Xoa Map Network Drive MRU
     - Xoa Cortana / Windows Search history

  8. ADVANCED CLEAN
     - Xoa Recycle Bin (Thung rac)
     - Xoa Windows Search Index
     - Xoa Clipboard History
     - Xoa Notification History
     - Xoa Diagnostic & Telemetry data
     - Xoa Windows Defender scan history
     - Reset CMD command history
     - Xoa lich su Paint, Notepad, WordPad
     * Tuy chon: Wipe Free Space (chong phuc hoi du lieu)

================================================================
CAU TRUC THU MUC
================================================================

  USB_DRIVE/
  |-- LAUNCHER.bat              <- Click dup de chay
  |-- README.txt                <- File nay
  |-- scripts/
  |   |-- main_cleaner.ps1      <- Script chinh
  |   |-- modules/
  |   |   |-- mod_detect_users.ps1
  |   |   |-- mod_event_logs.ps1
  |   |   |-- mod_usb_history.ps1
  |   |   |-- mod_file_history.ps1
  |   |   |-- mod_shellbags.ps1
  |   |   |-- mod_wifi_history.ps1
  |   |   |-- mod_browser_history.ps1
  |   |   |-- mod_app_history.ps1
  |   |   |-- mod_advanced_clean.ps1
  |   |-- utils/
  |       |-- logger.ps1
  |       |-- report.ps1
  |-- winpe/
  |   |-- offline_cleaner.bat   <- Chay trong WinPE
  |   |-- offline_cleaner.ps1
  |-- logs/                     <- Log & Bao cao (tu tao)
  |-- wifi_backup_*/            <- Backup WiFi (neu co)

================================================================
LUU Y QUAN TRONG
================================================================

  1. SAO LUU du lieu quan trong truoc khi su dung tool
  2. Thao tac xoa KHONG THE HOAN TAC
  3. Xoa WiFi se mat tat ca mat khau WiFi da luu
  4. Nen su dung DEEP CLEAN + WinPE de xoa triet de nhat
  5. Khong tat may khi tool dang chay
  6. Kiem tra bao cao trong thu muc logs/ sau khi chay

================================================================
  Phien ban: 1.0
  Tac gia  : USB Windows History Cleaner
  Ngay tao : 2026
================================================================
