# USB Windows History Cleaner

Windows Activity & Artifact Cleaner running portably from USB without requiring Windows reinstallation.

---

## Overview

USB Windows History Cleaner is a portable anti-forensics tool designed to purge system activity history, device connection logs, temporary files, network profiles, and application traces from Windows 10 and Windows 11 systems.

The tool operates directly from a USB flash drive, requires no installation, supports multi-user profiles, and includes a dry-run test mode as well as a bootable WinPE offline cleaner for locked system files.

---

## Technical Specifications

- Operating System: Windows 10 / Windows 11 (64-bit)
- Execution Environment: PowerShell 5.1+ (Built-in on Windows 10/11)
- Privilege Requirement: Administrator (Auto-elevated via UAC prompt)
- Storage Requirement: Minimum 64MB free space on USB
- Offline Capability: Fully functional without internet access

---

## Cleaning Modules Detail

### 1. Event Logs & System Diagnostics
- Windows Event Logs (Application, Security, System, WLAN, Setup, etc.)
- Windows Error Reporting (WER) archives and queue files
- Crash Dumps (Minidumps and MEMORY.DMP)
- Setup API logs (setupapi.dev.log, setupapi.app.log, Panther logs)

### 2. USB & Peripheral Device History
- Registry Key: `HKLM\SYSTEM\CurrentControlSet\Enum\USBSTOR`
- Registry Key: `HKLM\SYSTEM\CurrentControlSet\Enum\USB`
- Registry Key: `HKLM\SYSTEM\MountedDevices`
- Registry Key: `HKLM\SOFTWARE\Microsoft\Windows Portable Devices`
- Device Class GUID Associations (Disk, Volume, USB)
- Search Volume Info Cache and SCSI device records
- Automatic Protection: The active USB drive running the cleaner is automatically excluded from deletion.

### 3. File & Explorer History
- Prefetch Files (`C:\Windows\Prefetch`)
- Recent Documents, AutomaticDestinations, and CustomDestinations
- System & User Temp directories
- Explorer Thumbnail Cache (`thumbcache_*.db`) and Icon Cache (`IconCache.db`)
- Registry MRU Keys: RecentDocs, OpenSavePidlMRU, LastVisitedPidlMRU, RunMRU, TypedPaths, WordWheelQuery

### 4. Shell Bags & Folder View History
- Primary Shell Bags: `BagMRU` and `Bags` in `Software\Classes\Local Settings`
- Secondary Shell Bags in `Software\Microsoft\Windows`
- Menu Order Cache
- Window Position & Stream Cache (`StreamMRU`, `Streams`)

### 5. Wi-Fi & Network Profiles
- Saved Wi-Fi Profiles via `netsh wlan`
- WLAN Event Logs (`Microsoft-Windows-WLAN-AutoConfig/Operational`)
- Network List Profiles, Signatures, and NLA Cache in Registry
- Physical Interface XML Configuration Files
- Optional Feature: Automatic export/backup of Wi-Fi passwords to USB before deletion.

### 6. Universal Browser Cleaner
Automated detection and cleaning for over 24 web browsers:
- Chromium-based: Google Chrome, Microsoft Edge, Brave, Opera, Opera GX, Vivaldi, Cốc Cốc, Yandex, Chromium, Cent Browser, SRWare Iron, Comodo Dragon, Epic, Torch, UC Browser, Naver Whale.
- Firefox-based: Mozilla Firefox, Waterfox, Tor Browser, LibreWolf, Pale Moon, Basilisk, SeaMonkey, Thunderbird.
- Legacy: Internet Explorer, Legacy Edge.
- Cleaned Items: Browsing history, cache, cookies, session data, download history, GPU cache, and local storage. Bookmarks and saved passwords are preserved by default.

### 7. Application Traces & Windows Timeline
- Background Activity Moderator (BAM / DAM) registry keys
- UserAssist program execution records
- Application Compatibility Assistant history
- MUI Cache
- Windows Timeline data (`ConnectedDevicesPlatform`)
- PowerShell Console Command History (`ConsoleHost_history.txt`)
- Remote Desktop Connection History (RDP MRU)
- Mapped Network Drives MRU
- Cortana & Windows Search Recent Apps

### 8. Advanced Artifacts
- Recycle Bin purge across all attached storage drives
- Windows Search Index database
- System Clipboard history
- Action Center Notification database
- Diagnostic ETW logs and SleepStudy logs
- Windows Defender scan history
- CMD session doskey history
- Built-in app recent file lists (Paint, Notepad, WordPad)
- Optional Feature: Free space wiping via `cipher /w:C:` to prevent file recovery.

### 9. System Cache & Network Flushing
- DNS Client Cache flush (`ipconfig /flushdns`)
- ARP Cache reset (`arp -d *`, `netsh interface ip delete arpcache`)
- Windows Font Cache reset
- Windows Update Download Cache purge (`SoftwareDistribution\Download`)
- Delivery Optimization Cache purge
- Windows Store LocalCache reset
- Scheduled Tasks execution logs
- Volume Shadow Copies purge (`vssadmin delete shadows`)
- Optional removal of leftover `Windows.old` directories
- BITS Transfer job history
- Print Spooler queue cleanup
- Cached Network Credentials cleanup

---

## Directory Structure

```text
USB_ROOT/
├── LAUNCHER.bat           Primary entry point (elevates UAC and runs cleaner)
├── TEST_MODE.bat          Runs tool in Dry-Run mode (simulation only)
├── AUTO_DEEPCLEAN.bat     Runs Deep Clean without interactive module prompts
├── autorun.inf            Windows AutoPlay and context menu configuration
├── README.md              Documentation file
├── README.txt              Text version documentation
├── scripts/
│   ├── main_cleaner.ps1   Master orchestrator script
│   ├── modules/
│   │   ├── mod_detect_users.ps1
│   │   ├── mod_event_logs.ps1
│   │   ├── mod_usb_history.ps1
│   │   ├── mod_file_history.ps1
│   │   ├── mod_shellbags.ps1
│   │   ├── mod_wifi_history.ps1
│   │   ├── mod_browser_history.ps1
│   │   ├── mod_app_history.ps1
│   │   ├── mod_advanced_clean.ps1
│   │   └── mod_system_cache.ps1
│   └── utils/
│       ├── logger.ps1
│       └── report.ps1
├── winpe/
│   ├── offline_cleaner.bat
│   └── offline_cleaner.ps1
└── tests/
    └── test_on_linux.sh
```

---

## Usage Instructions

### Method 1: Portable Execution in Windows

1. Copy all contents of this repository to the root directory of a USB drive.
2. Insert the USB drive into the target Windows computer.
3. Choose execution method:
   - For interactive execution: Double-click `LAUNCHER.bat`.
   - For safe simulation: Double-click `TEST_MODE.bat`.
   - For automated full clean: Double-click `AUTO_DEEPCLEAN.bat`.
4. Accept the User Account Control (UAC) prompt to grant Administrator privileges.
5. Select target user profile(s) when prompted.
6. Confirm execution by entering `XOA` when prompted.
7. Review execution summary and log files generated in the `logs/` directory.

### Method 2: Offline Cleaning via WinPE Boot

Use this method to purge files locked during active Windows sessions (such as active WLAN log files).

1. Boot the machine using a WinPE USB drive containing this tool directory.
2. Open Command Prompt in WinPE and navigate to the USB drive directory.
3. Enter the `winpe/` directory and execute `offline_cleaner.bat`.
4. The script will locate the offline Windows system partition, mount offline Registry hives (`SYSTEM`, `SOFTWARE`, `NTUSER.DAT`), and perform deep offline cleaning.
5. Reboot the computer into normal Windows mode upon completion.

---

## Command Line Arguments

`LAUNCHER.bat` supports command line flags:

- `LAUNCHER.bat --test` or `LAUNCHER.bat --dryrun`: Enables Dry-Run simulation mode.
- `LAUNCHER.bat --auto`: Runs Deep Clean mode automatically.
- `LAUNCHER.bat --auto-test`: Combines Dry-Run mode with automated execution.

---

## Safety & Error Handling

- Non-destructive Error Handling: All file and registry modifications are wrapped in exception blocks (`try/catch`). Errors are logged without halting system execution or corrupting Windows system state.
- Drive Protection: The tool detects its own USB drive serial number and logical drive letter to prevent deleting the cleaner script itself or unmounting the active USB drive.
- Post-Clean Verification: After cleaning, the system performs a verification scan and outputs a cleanliness percentage score.

---

## Linux Verification Suite

To verify script integrity, line endings, and module dependencies on a Linux workstation prior to deploying onto a USB drive:

```bash
bash /home/vantrong/Downloads/usb_dl/tests/test_on_linux.sh
```

---

## License

Distributed under the MIT License. See LICENSE for more information.
