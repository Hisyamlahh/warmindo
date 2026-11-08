#!/usr/bin/env bash
# ==============================================================================
# Script: run-maestro-tests.sh
# Menjalankan pengujian otomatis Maestro UI E2E untuk Warmindo JugaJago
# ==============================================================================

set -e

# Warna output terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   Warmindo JugaJago - Maestro E2E UI Test Runner  ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Periksa apakah Maestro CLI sudah terinstall
if ! command -v maestro &> /dev/null; then
    echo -e "${RED}[ERROR] Maestro CLI belum terpasang di sistem!${NC}"
    echo -e "${YELLOW}Silakan pasang Maestro terlebih dahulu:${NC}"
    echo "  - macOS / Linux : curl -Ls 'https://get.maestro.mobile.dev' | bash"
    echo "  - Windows       : Jalankan via Git Bash / WSL atau ikuti panduan: https://maestro.mobile.dev/getting-started/installing-maestro"
    exit 1
fi

echo -e "${GREEN}[OK] Maestro CLI terdeteksi:${NC} $(maestro --version || echo 'Maestro')"

# 2. Periksa apakah perangkat / emulator Android terhubung via adb
if command -v adb &> /dev/null; then
    DEVICES=$(adb devices | grep -v "List" | grep "device" || true)
    if [ -z "$DEVICES" ]; then
        echo -e "${YELLOW}[WARNING] Tidak ada perangkat/emulator Android yang aktif via ADB!${NC}"
        echo -e "Pastikan emulator Android sudah berjalan atau HP Android terhubung dengan USB Debugging aktif."
    else
        echo -e "${GREEN}[OK] Perangkat Android terdeteksi:${NC}"
        echo "$DEVICES"
    fi
fi

# 3. Direktori flows
FLOWS_DIR="maestro/flows"

if [ ! -d "$FLOWS_DIR" ]; then
    echo -e "${RED}[ERROR] Folder $FLOWS_DIR tidak ditemukan!${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Memulai eksekusi pengujian Maestro flows...${NC}\n"

# Jalankan flow pengujian spesifik atau seluruh folder
if [ -n "$1" ]; then
    TARGET_FLOW="$FLOWS_DIR/$1"
    if [ -f "$TARGET_FLOW" ]; then
        echo -e "${BLUE}>>> Menjalankan flow: $TARGET_FLOW${NC}"
        maestro test "$TARGET_FLOW"
    else
        echo -e "${RED}[ERROR] File $TARGET_FLOW tidak ditemukan!${NC}"
        exit 1
    fi
else
    echo -e "${BLUE}>>> 1. Menjalankan Landing Flow (maestro/flows/landing.yaml)...${NC}"
    maestro test "$FLOWS_DIR/landing.yaml"

    echo -e "\n${BLUE}>>> 2. Menjalankan Login & Navigasi Tab Flow (maestro/flows/login.yaml)...${NC}"
    maestro test "$FLOWS_DIR/login.yaml"

    echo -e "\n${BLUE}>>> 3. Menjalankan Order, Pembayaran & Riwayat Flow (maestro/flows/order_checkout.yaml)...${NC}"
    maestro test "$FLOWS_DIR/order_checkout.yaml"

    echo -e "\n${BLUE}>>> 4. Menjalankan Scrolling Flow (maestro/flows/scrolling.yaml)...${NC}"
    maestro test "$FLOWS_DIR/scrolling.yaml"

    echo -e "\n${BLUE}>>> 5. Menjalankan Riwayat & Manajemen Order Flow (maestro/flows/riwayat.yaml)...${NC}"
    maestro test "$FLOWS_DIR/riwayat.yaml"
fi

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   Seluruh Pengujian Maestro Berhasil Diselesaikan!  ${NC}"
echo -e "${GREEN}====================================================${NC}"

