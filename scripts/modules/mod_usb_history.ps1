# ============================================================
# USB Windows History Cleaner - Module: USB/Device History
# Xoa lich su thiet bi USB, o cung roi, thiet bi ngoai vi
# ============================================================

function Clear-USBHistory {
    <#
    .SYNOPSIS
    Xoa toan bo lich su thiet bi USB/ngoai vi tu Registry va file system
    Bao ve USB dang chay tool
    #>
    param(
        [bool]$DryRun = $false
    )

    Write-Log "XOA LICH SU THIET BI USB / NGOAI VI" -Level "HEADER"

    $totalDeleted = 0
    $errors = 0

    # ============================================================
    # Xac dinh USB dang su dung (de bao ve)
    # ============================================================

    $scriptDrive = (Split-Path -Path $PSScriptRoot -Qualifier) -replace ":"
    Write-Log "USB dang chay tool: Drive $scriptDrive - SE DUOC BAO VE" -Level "WARNING"

    # Lay thong tin USB dang dung
    $currentUSBSerial = $null
    try {
        $currentDisk = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "$scriptDrive`:" }
        if ($currentDisk) {
            $partition = Get-WmiObject -Query "ASSOCIATORS OF {Win32_LogicalDisk.DeviceID='$scriptDrive`:'} WHERE AssocClass=Win32_LogicalDiskToPartition"
            if ($partition) {
                $disk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
                if ($disk) {
                    $currentUSBSerial = $disk.SerialNumber
                    Write-Log "Serial USB hien tai: $currentUSBSerial" -Level "DETAIL"
                }
            }
        }
    } catch {
        Write-Log "Khong the xac dinh serial USB hien tai" -Level "WARNING"
    }

    # ============================================================
    # 1. Xoa USBSTOR Registry
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 1: Xoa USBSTOR Registry..." -Level "INFO"

    $usbstorPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"
    if (Test-Path $usbstorPath) {
        try {
            $devices = Get-ChildItem -Path $usbstorPath -ErrorAction SilentlyContinue
            foreach ($device in $devices) {
                $subDevices = Get-ChildItem -Path $device.PSPath -ErrorAction SilentlyContinue
                foreach ($subDevice in $subDevices) {
                    $serial = $subDevice.PSChildName
                    # Bao ve USB dang dung
                    if ($currentUSBSerial -and $serial -like "*$currentUSBSerial*") {
                        Write-Log "Bo qua USB dang su dung: $serial" -Level "WARNING"
                        continue
                    }
                    try {
                        Remove-Item -Path $subDevice.PSPath -Recurse -Force -ErrorAction Stop
                        $totalDeleted++
                        Write-Log "Xoa USBSTOR device: $($device.PSChildName)\$serial" -Level "SUCCESS"
                    } catch {
                        # Thu voi reg.exe
                        $regPath = $subDevice.Name -replace "HKEY_LOCAL_MACHINE", "HKLM"
                        reg delete $regPath /f 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            $totalDeleted++
                        } else {
                            $errors++
                            Write-Log "Khong the xoa: $serial - $($_.Exception.Message)" -Level "ERROR"
                        }
                    }
                }
            }
        } catch {
            Write-Log "Loi khi xu ly USBSTOR: $($_.Exception.Message)" -Level "ERROR"
            $errors++
        }
    }

    # ============================================================
    # 2. Xoa USB Enum Registry
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 2: Xoa USB Enum Registry..." -Level "INFO"

    $usbEnumPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB"
    if (Test-Path $usbEnumPath) {
        try {
            $vidPids = Get-ChildItem -Path $usbEnumPath -ErrorAction SilentlyContinue
            $removedCount = 0
            foreach ($vidPid in $vidPids) {
                # Bo qua cac thiet bi dang hoat dong (hub, keyboard, mouse)
                $friendlyName = (Get-ItemProperty -Path $vidPid.PSPath -ErrorAction SilentlyContinue)."FriendlyName"

                $subItems = Get-ChildItem -Path $vidPid.PSPath -ErrorAction SilentlyContinue
                foreach ($subItem in $subItems) {
                    try {
                        Remove-Item -Path $subItem.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                        $removedCount++
                    } catch {
                        # Mot so key khong the xoa vi thiet bi dang su dung - binh thuong
                    }
                }
            }
            Write-Log "Xoa $removedCount USB enum entries" -Level "SUCCESS"
            $totalDeleted += $removedCount
        } catch {
            Write-Log "Loi khi xu ly USB Enum: $($_.Exception.Message)" -Level "WARNING"
        }
    }

    # ============================================================
    # 3. Xoa MountedDevices
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 3: Xoa MountedDevices Registry..." -Level "INFO"

    $mountedPath = "HKLM:\SYSTEM\MountedDevices"
    if (Test-Path $mountedPath) {
        try {
            $properties = Get-ItemProperty -Path $mountedPath -ErrorAction SilentlyContinue
            $removedCount = 0

            foreach ($prop in $properties.PSObject.Properties) {
                # Bo qua drive hien tai va system drives
                if ($prop.Name -like "\DosDevices\$scriptDrive`:*" -or
                    $prop.Name -like "\DosDevices\C:*" -or
                    $prop.Name -eq "PSPath" -or $prop.Name -eq "PSParentPath" -or
                    $prop.Name -eq "PSChildName" -or $prop.Name -eq "PSProvider" -or
                    $prop.Name -eq "PSDrive") {
                    continue
                }

                if ($prop.Name -like "\DosDevices\*" -or $prop.Name -like "#{*") {
                    try {
                        Remove-ItemProperty -Path $mountedPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                        $removedCount++
                    } catch {
                        # Ignore
                    }
                }
            }
            Write-Log "Xoa $removedCount MountedDevices entries" -Level "SUCCESS"
            $totalDeleted += $removedCount
        } catch {
            Write-Log "Loi khi xu ly MountedDevices: $($_.Exception.Message)" -Level "WARNING"
        }
    }

    # ============================================================
    # 4. Xoa Portable Devices Registry
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 4: Xoa Windows Portable Devices..." -Level "INFO"

    $portableDevPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows Portable Devices\Devices",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt"
    )

    foreach ($path in $portableDevPaths) {
        if (Test-Path $path) {
            try {
                $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
                $removedCount = 0
                foreach ($item in $items) {
                    try {
                        Remove-Item -Path $item.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                        $removedCount++
                    } catch {
                        # Ignore protected keys
                    }
                }
                Write-Log "Xoa $removedCount entries tu $(Split-Path $path -Leaf)" -Level "SUCCESS"
                $totalDeleted += $removedCount
            } catch {
                $errors++
            }
        }
    }

    # ============================================================
    # 5. Xoa DeviceClasses
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 5: Xoa Device Classes associations..." -Level "INFO"

    $deviceClassGuids = @(
        "{53f56307-b6bf-11d0-94f2-00a0c91efb8b}",  # Disk
        "{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}",  # Volume
        "{a5dcbf10-6530-11d2-901f-00c04fb951ed}"    # USB
    )

    foreach ($guid in $deviceClassGuids) {
        $classPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceClasses\$guid"
        if (Test-Path $classPath) {
            try {
                $items = Get-ChildItem -Path $classPath -ErrorAction SilentlyContinue
                $removedCount = 0
                foreach ($item in $items) {
                    try {
                        Remove-Item -Path $item.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                        $removedCount++
                    } catch { }
                }
                Write-Log "Xoa $removedCount entries tu DeviceClasses $guid" -Level "SUCCESS"
                $totalDeleted += $removedCount
            } catch {
                $errors++
            }
        }
    }

    # ============================================================
    # 6. Xoa Volume Info Cache
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 6: Xoa Volume Info Cache va SCSI..." -Level "INFO"

    $volumeCachePaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows Search\VolumeInfoCache",
        "HKLM:\SYSTEM\CurrentControlSet\Enum\SCSI"
    )

    foreach ($path in $volumeCachePaths) {
        if (Test-Path $path) {
            try {
                $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
                $removedCount = 0
                foreach ($item in $items) {
                    try {
                        Remove-Item -Path $item.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                        $removedCount++
                    } catch { }
                }
                Write-Log "Xoa $removedCount entries tu $(Split-Path $path -Leaf)" -Level "SUCCESS"
                $totalDeleted += $removedCount
            } catch { }
        }
    }

    # ============================================================
    # 7. Xoa file setupapi log
    # ============================================================

    Write-LogSeparator
    Write-Log "Buoc 7: Xoa Setup API logs..." -Level "INFO"

    $setupFiles = @(
        "$env:SystemRoot\INF\setupapi.dev.log",
        "$env:SystemRoot\INF\setupapi.app.log",
        "$env:SystemRoot\setupapi.log"
    )

    foreach ($file in $setupFiles) {
        if (Test-Path $file) {
            try {
                Remove-Item -Path $file -Force -ErrorAction Stop
                Write-Log "Xoa: $(Split-Path $file -Leaf)" -Level "SUCCESS"
                $totalDeleted++
            } catch {
                # Thu ghi de file rong
                try {
                    "" | Out-File -FilePath $file -Force
                    Write-Log "Da lam rong: $(Split-Path $file -Leaf)" -Level "SUCCESS"
                } catch {
                    $errors++
                }
            }
        }
    }

    # Cap nhat stats
    Add-CleanStat -Category "RegistryKeysDeleted" -Count $totalDeleted
    Add-CleanStat -Category "Errors" -Count $errors

    Write-LogSeparator
    Write-Log "Hoan tat xoa USB History. Tong: $totalDeleted, Loi: $errors" -Level "INFO"
}
