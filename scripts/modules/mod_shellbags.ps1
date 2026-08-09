# ============================================================
# USB Windows History Cleaner - Module: Shell Bags
# Xoa lich su duyet thu muc (Shell Bags)
# ============================================================

function Clear-ShellBags {
    <#
    .SYNOPSIS
    Xoa Shell Bags - lich su kieu hien thi va vi tri cua so cho tung thu muc
    #>
    param(
        [PSCustomObject[]]$Users,
        [bool]$DryRun = $false
    )

    Write-Log "XOA SHELL BAGS (LICH SU DUYET THU MUC)" -Level "HEADER"

    $totalDeleted = 0
    $errors = 0

    foreach ($user in $Users) {
        Write-Log "Xu ly Shell Bags cho user: $($user.Name)..." -Level "INFO"

        $regBase = Get-UserRegistryPath -User $user
        if (-not $regBase) {
            Write-Log "Khong the truy cap registry cua user: $($user.Name)" -Level "WARNING"
            $errors++
            continue
        }

        # Danh sach Shell Bag registry paths
        $shellBagPaths = @(
            # Primary Shell Bags
            "$regBase\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU",
            "$regBase\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags",

            # Secondary Shell Bags
            "$regBase\Software\Microsoft\Windows\Shell\BagMRU",
            "$regBase\Software\Microsoft\Windows\Shell\Bags",

            # Desktop Shell Bags
            "$regBase\Software\Microsoft\Windows\ShellNoRoam\BagMRU",
            "$regBase\Software\Microsoft\Windows\ShellNoRoam\Bags"
        )

        foreach ($path in $shellBagPaths) {
            if (Test-Path $path) {
                try {
                    # Dem truoc khi xoa
                    $subKeyCount = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count

                    # Xoa toan bo subkeys
                    Get-ChildItem -Path $path -ErrorAction SilentlyContinue |
                        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

                    # Xoa tat ca values
                    $props = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                    if ($props) {
                        foreach ($prop in $props.PSObject.Properties) {
                            if ($prop.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSProvider", "PSDrive")) {
                                Remove-ItemProperty -Path $path -Name $prop.Name -Force -ErrorAction SilentlyContinue
                            }
                        }
                    }

                    $keyName = ($path -split "\\")[-2..-1] -join "\"
                    Write-Log "Xoa $subKeyCount Shell Bag entries: $keyName" -Level "SUCCESS"
                    $totalDeleted += $subKeyCount
                } catch {
                    Write-Log "Loi xoa Shell Bags: $($_.Exception.Message)" -Level "WARNING"
                    $errors++
                }
            }
        }

        # Xoa Menu Order Cache
        $menuOrderPath = "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\MenuOrder"
        if (Test-Path $menuOrderPath) {
            try {
                Get-ChildItem -Path $menuOrderPath -ErrorAction SilentlyContinue |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Xoa Menu Order Cache" -Level "SUCCESS"
                $totalDeleted++
            } catch {
                $errors++
            }
        }

        # Xoa StreamMRU (luu vi tri cua so)
        $streamMRUPath = "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\StreamMRU"
        if (Test-Path $streamMRUPath) {
            try {
                Remove-Item -Path $streamMRUPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Xoa StreamMRU" -Level "SUCCESS"
                $totalDeleted++
            } catch {
                $errors++
            }
        }

        # Xoa Streams (vi tri va kich thuoc cua so)
        $streamsPath = "$regBase\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams"
        if (Test-Path $streamsPath) {
            try {
                Get-ChildItem -Path $streamsPath -ErrorAction SilentlyContinue |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Xoa Explorer Streams" -Level "SUCCESS"
                $totalDeleted++
            } catch {
                $errors++
            }
        }

        # Unload registry cho user khac
        Unload-UserRegistry -User $user

        Write-LogSeparator
    }

    # Cap nhat stats
    Add-CleanStat -Category "RegistryKeysDeleted" -Count $totalDeleted
    Add-CleanStat -Category "Errors" -Count $errors

    Write-Log "Hoan tat xoa Shell Bags. Tong: $totalDeleted, Loi: $errors" -Level "INFO"
}
