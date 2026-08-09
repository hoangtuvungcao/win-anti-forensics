# ============================================================
# USB Windows History Cleaner - Module: Detect Users
# Phat hien va chon user tren he thong
# ============================================================

function Get-WindowsUsers {
    <#
    .SYNOPSIS
    Quet tat ca user profiles tren he thong Windows
    Tra ve danh sach user co profile thuc (loai bo system profiles)
    #>

    $systemProfiles = @("Default", "Default User", "Public", "All Users")
    $usersPath = "$env:SystemDrive\Users"

    $users = @()

    if (Test-Path $usersPath) {
        $profiles = Get-ChildItem -Path $usersPath -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notin $systemProfiles }

        foreach ($profile in $profiles) {
            $ntUserPath = Join-Path $profile.FullName "NTUSER.DAT"
            $hasNtUser = Test-Path $ntUserPath

            # Kiem tra user co phai admin khong
            $isAdmin = $false
            try {
                $localUser = Get-LocalUser -Name $profile.Name -ErrorAction SilentlyContinue
                if ($localUser) {
                    $groups = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
                    $isAdmin = $groups | Where-Object { $_.Name -like "*\$($profile.Name)" }
                }
            } catch {
                # Ignore - co the khong co quyen query
            }

            if ($hasNtUser) {
                $users += [PSCustomObject]@{
                    Name        = $profile.Name
                    ProfilePath = $profile.FullName
                    IsAdmin     = [bool]$isAdmin
                    HasNtUser   = $hasNtUser
                    SID         = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" -ErrorAction SilentlyContinue |
                                   Where-Object { $_.ProfileImagePath -eq $profile.FullName }).PSChildName
                }
            }
        }
    }

    return $users
}

function Select-Users {
    <#
    .SYNOPSIS
    Hien thi menu chon user. Tu dong chon neu chi co 1 user.
    #>
    param(
        [bool]$DryRun = $false
    )

    $users = Get-WindowsUsers

    if ($users.Count -eq 0) {
        Write-Log "Khong tim thay user nao tren he thong!" -Level "ERROR"
        return $null
    }

    if ($users.Count -eq 1) {
        Write-Log "Chi co 1 user: $($users[0].Name) - Tu dong chon." -Level "INFO"
        return @($users[0])
    }

    # Hien thi menu chon user
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host "         CHON USER CAN XOA LICH SU" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host ""

    for ($i = 0; $i -lt $users.Count; $i++) {
        $adminTag = if ($users[$i].IsAdmin) { " (Administrator)" } else { "" }
        $currentTag = if ($users[$i].Name -eq $env:USERNAME) { " [DANG DANG NHAP]" } else { "" }
        Write-Host "  [$($i + 1)] $($users[$i].Name)$adminTag$currentTag" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "  [A] Tat ca user" -ForegroundColor Yellow
    Write-Host "  [0] Quay lai" -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-Host "  Chon user (1-$($users.Count), A=Tat ca, 0=Quay lai)"

    if ($choice -eq "0") {
        return $null
    }

    if ($choice -eq "A" -or $choice -eq "a") {
        Write-Log "Da chon: TAT CA user ($($users.Count) users)" -Level "INFO"
        return $users
    }

    try {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $users.Count) {
            Write-Log "Da chon user: $($users[$index].Name)" -Level "INFO"
            return @($users[$index])
        } else {
            Write-Log "Lua chon khong hop le!" -Level "ERROR"
            return $null
        }
    } catch {
        Write-Log "Lua chon khong hop le!" -Level "ERROR"
        return $null
    }
}

function Get-UserRegistryPath {
    <#
    .SYNOPSIS
    Tra ve duong dan registry cho user cu the (load NTUSER.DAT neu can)
    #>
    param(
        [PSCustomObject]$User
    )

    if ($User.Name -eq $env:USERNAME) {
        # User hien tai - dung HKCU truc tiep
        return "HKCU:"
    }

    # User khac - can load NTUSER.DAT
    $ntUserPath = Join-Path $User.ProfilePath "NTUSER.DAT"
    $hiveName = "HKU_$($User.Name)"

    if (Test-Path $ntUserPath) {
        # Kiem tra xem hive da load chua
        $loadedHives = reg query HKU 2>$null | Where-Object { $_ -match $hiveName }
        if (-not $loadedHives) {
            try {
                reg load "HKU\$hiveName" "$ntUserPath" 2>$null
                Write-Log "Da load registry hive cho user: $($User.Name)" -Level "DETAIL"
            } catch {
                Write-Log "Khong the load registry cho user: $($User.Name) - $($_.Exception.Message)" -Level "ERROR"
                return $null
            }
        }
        return "Registry::HKU\$hiveName"
    }

    return $null
}

function Unload-UserRegistry {
    <#
    .SYNOPSIS
    Unload registry hive cua user da load truoc do
    #>
    param(
        [PSCustomObject]$User
    )

    if ($User.Name -ne $env:USERNAME) {
        $hiveName = "HKU_$($User.Name)"
        try {
            [gc]::Collect()
            Start-Sleep -Milliseconds 500
            reg unload "HKU\$hiveName" 2>$null
            Write-Log "Da unload registry hive cho user: $($User.Name)" -Level "DETAIL"
        } catch {
            Write-Log "Khong the unload registry cho user: $($User.Name)" -Level "WARNING"
        }
    }
}
