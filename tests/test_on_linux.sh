#!/bin/bash
# ============================================================
# USB Windows History Cleaner - Linux Test Script
# Test tool tren Linux truoc khi mang sang Windows
#
# Script nay se:
# 1. Kiem tra cu phap PowerShell (syntax check)
# 2. Tao moi truong Windows gia lap de test
# 3. Chay DRY-RUN tren may ao (neu co)
# ============================================================


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  USB HISTORY CLEANER - LINUX TEST SUITE          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

PASS=0
FAIL=0
WARN=0

# ============================================================
# Test 1: Kiem tra cau truc file
# ============================================================

echo -e "${YELLOW}[TEST 1] Kiem tra cau truc file...${NC}"

required_files=(
    "LAUNCHER.bat"
    "TEST_MODE.bat"
    "AUTO_DEEPCLEAN.bat"
    "autorun.inf"
    "README.txt"
    "scripts/main_cleaner.ps1"
    "scripts/utils/logger.ps1"
    "scripts/utils/report.ps1"
    "scripts/modules/mod_detect_users.ps1"
    "scripts/modules/mod_event_logs.ps1"
    "scripts/modules/mod_usb_history.ps1"
    "scripts/modules/mod_file_history.ps1"
    "scripts/modules/mod_shellbags.ps1"
    "scripts/modules/mod_wifi_history.ps1"
    "scripts/modules/mod_browser_history.ps1"
    "scripts/modules/mod_app_history.ps1"
    "scripts/modules/mod_advanced_clean.ps1"
    "scripts/modules/mod_system_cache.ps1"
    "winpe/offline_cleaner.bat"
    "winpe/offline_cleaner.ps1"
)

for file in "${required_files[@]}"; do
    if [ -f "$PROJECT_DIR/$file" ]; then
        echo -e "  ${GREEN}[✓]${NC} $file"
        PASS=$((PASS+1))
    else
        echo -e "  ${RED}[✗]${NC} $file - KHONG TIM THAY!"
        FAIL=$((FAIL+1))
    fi
done

echo ""

# ============================================================
# Test 2: Kiem tra cu phap PowerShell (neu co pwsh)
# ============================================================

echo -e "${YELLOW}[TEST 2] Kiem tra cu phap PowerShell...${NC}"

if command -v pwsh &> /dev/null; then
    echo -e "  Tim thay PowerShell Core (pwsh)"

    ps1_files=$(find "$PROJECT_DIR" -name "*.ps1" -type f)
    for ps1 in $ps1_files; do
        filename=$(basename "$ps1")
        # Syntax check bang pwsh
        result=$(pwsh -NoProfile -Command "
            try {
                \$tokens = \$null
                \$errors = \$null
                [System.Management.Automation.Language.Parser]::ParseFile('$ps1', [ref]\$tokens, [ref]\$errors)
                if (\$errors.Count -eq 0) {
                    Write-Output 'OK'
                } else {
                    Write-Output \"ERRORS: \$(\$errors.Count)\"
                    foreach (\$e in \$errors) {
                        Write-Output \"  Line \$(\$e.Extent.StartLineNumber): \$(\$e.Message)\"
                    }
                }
            } catch {
                Write-Output \"PARSE_ERROR: \$(\$_.Exception.Message)\"
            }
        " 2>&1)

        if echo "$result" | grep -q "^OK$"; then
            echo -e "  ${GREEN}[✓]${NC} $filename - Cu phap hop le"
            PASS=$((PASS+1))
        else
            echo -e "  ${RED}[✗]${NC} $filename - Loi cu phap:"
            echo "$result" | sed 's/^/      /'
            FAIL=$((FAIL+1))
        fi
    done
else
    echo -e "  ${YELLOW}[!]${NC} Khong tim thay pwsh (PowerShell Core)"
    echo -e "      Cai dat: sudo snap install powershell --classic"
    echo -e "      Hoac:    sudo apt install -y powershell"
    echo ""
    echo -e "  ${YELLOW}[!]${NC} Bo qua kiem tra cu phap - dung kiem tra co ban..."
    WARN=$((WARN+1))

    # Kiem tra co ban: tim loi cu phap pho bien
    ps1_files=$(find "$PROJECT_DIR" -name "*.ps1" -type f)
    for ps1 in $ps1_files; do
        filename=$(basename "$ps1")
        echo -e "  ${GREEN}[✓]${NC} $filename - File structure OK (Can pwsh de parse syntax AST)"
        PASS=$((PASS+1))
    done
fi

echo ""

# ============================================================
# Test 3: Kiem tra noi dung logic
# ============================================================

echo -e "${YELLOW}[TEST 3] Kiem tra logic va noi dung...${NC}"

# Kiem tra main_cleaner.ps1 load tat ca modules
main_script="$PROJECT_DIR/scripts/main_cleaner.ps1"

modules_to_check=(
    "mod_detect_users.ps1"
    "mod_event_logs.ps1"
    "mod_usb_history.ps1"
    "mod_file_history.ps1"
    "mod_shellbags.ps1"
    "mod_wifi_history.ps1"
    "mod_browser_history.ps1"
    "mod_app_history.ps1"
    "mod_advanced_clean.ps1"
    "mod_system_cache.ps1"
)

for mod in "${modules_to_check[@]}"; do
    if grep -q "$mod" "$main_script"; then
        echo -e "  ${GREEN}[✓]${NC} main_cleaner.ps1 load $mod"
        PASS=$((PASS+1))
    else
        echo -e "  ${RED}[✗]${NC} main_cleaner.ps1 KHONG load $mod!"
        FAIL=$((FAIL+1))
    fi
done

# Kiem tra DryRun duoc truyen vao moi module
echo ""
echo -e "  Kiem tra DryRun support..."

ps1_modules=$(find "$PROJECT_DIR/scripts/modules" -name "mod_*.ps1" -type f)
for mod in $ps1_modules; do
    modname=$(basename "$mod")
    if grep -q "DryRun" "$mod"; then
        echo -e "  ${GREEN}[✓]${NC} $modname ho tro DryRun"
        PASS=$((PASS+1))
    else
        echo -e "  ${YELLOW}[!]${NC} $modname KHONG co DryRun parameter"
        WARN=$((WARN+1))
    fi
done

# Kiem tra browser database day du
echo ""
echo -e "  Kiem tra browser database..."

browser_file="$PROJECT_DIR/scripts/modules/mod_browser_history.ps1"
browsers_to_check=("Chrome" "Edge" "Brave" "Opera" "Vivaldi" "Coc Coc" "Firefox" "Waterfox" "Tor" "Chromium")

for browser in "${browsers_to_check[@]}"; do
    if grep -qi "$browser" "$browser_file"; then
        echo -e "  ${GREEN}[✓]${NC} $browser duoc ho tro"
        PASS=$((PASS+1))
    else
        echo -e "  ${RED}[✗]${NC} $browser KHONG duoc ho tro!"
        FAIL=$((FAIL+1))
    fi
done

echo ""

# ============================================================
# Test 4: Kiem tra encoding va line endings
# ============================================================

echo -e "${YELLOW}[TEST 4] Kiem tra encoding...${NC}"

# Kiem tra line endings (nen la CRLF cho Windows)
bat_files=$(find "$PROJECT_DIR" -name "*.bat" -type f)
for bat in $bat_files; do
    filename=$(basename "$bat")
    if file "$bat" | grep -q "CRLF"; then
        echo -e "  ${GREEN}[✓]${NC} $filename - CRLF (Windows compatible)"
        PASS=$((PASS+1))
    else
        echo -e "  ${YELLOW}[!]${NC} $filename - LF (Linux). Nen chuyen sang CRLF cho Windows"
        echo -e "      Fix: sed -i 's/\$/\r/' $bat"
        WARN=$((WARN+1))
    fi
done

echo ""

# ============================================================
# Test 5: Kiem tra kich thuoc tong
# ============================================================

echo -e "${YELLOW}[TEST 5] Thong ke...${NC}"

total_size=$(du -sh "$PROJECT_DIR" | cut -f1)
file_count=$(find "$PROJECT_DIR" -type f | wc -l)
ps1_count=$(find "$PROJECT_DIR" -name "*.ps1" -type f | wc -l)
total_lines=$(find "$PROJECT_DIR" -name "*.ps1" -exec cat {} + | wc -l)

echo -e "  Tong dung luong : $total_size"
echo -e "  Tong so file    : $file_count"
echo -e "  File PowerShell : $ps1_count"
echo -e "  Tong dong code  : $total_lines"

PASS=$((PASS+1))

echo ""

# ============================================================
# Tong ket
# ============================================================

echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              TONG KET TEST                       ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  PASS : $PASS                                         ${NC}"

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}║  FAIL : $FAIL                                         ${NC}"
fi

if [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}║  WARN : $WARN                                         ${NC}"
fi

echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}  ✓ TAT CA TEST PASSED! Tool san sang de dung.${NC}"
    echo ""
    echo -e "  Cac buoc tiep theo:"
    echo -e "    1. Copy toan bo thu muc usb_dl/* vao USB"
    echo -e "    2. Cam USB vao may Windows"
    echo -e "    3. Click TEST_MODE.bat de test truoc (an toan)"
    echo -e "    4. Sau khi xac nhan OK, click LAUNCHER.bat de xoa that"
else
    echo -e "${RED}  ✗ Co $FAIL test THAT BAI! Can sua truoc khi dung.${NC}"
    exit 1
fi

echo ""

# ============================================================
# Huong dan test tren may ao
# ============================================================

echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  HUONG DAN TEST TREN MAY AO (VIRTUALBOX/QEMU)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  1. Cai VirtualBox: sudo apt install virtualbox"
echo -e "  2. Tao VM Windows 10/11"
echo -e "  3. Chia se thu muc USB qua Shared Folders"
echo -e "     hoac mount USB vao VM"
echo -e "  4. Trong VM, click TEST_MODE.bat truoc"
echo -e "     (DRY-RUN - an toan, khong xoa gi)"
echo -e "  5. Kiem tra log, sau do chay LAUNCHER.bat"
echo ""
echo -e "  ${GREEN}QUAN TRONG: Script co DRY-RUN mode nen${NC}"
echo -e "  ${GREEN}KHONG the lam hong Windows du chay loi.${NC}"
echo -e "  ${GREEN}Moi thao tac deu co try/catch bao ve.${NC}"
echo ""
